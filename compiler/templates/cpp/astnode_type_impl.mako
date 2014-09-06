## vim: filetype=cpp

long ${cls.name().lower()}_counter = 0;

${cls.name()}::~${cls.name()}() {
        /* In C++, the mother class' destructor is automatically called at the
           end of this function, so iterate only on own fields.  */
        % for t, f in cls_field_decls:
            % if t.is_ptr:
                if (${f.name}) ${f.name}->dec_ref();
            % endif
        % endfor
#if DEBUG_MODE
        printf("%s", indent_str.c_str());
        printf("DELETING NODE with type ${cls.name()}\n");
#endif
}

std::string ${cls.name()}::repr() {
    std::string result = this->__name() + "(";

    % for i, (t, f) in enumerate(d for d in all_field_decls if d[1].repr):
        % if i > 0:
            result.append(", ");
        % endif

        % if t.is_ptr:
            if (${f.name} != ${t.nullexpr()}) {
        % endif

            result.append(get_repr(${f.name}));

        % if t.is_ptr:
            } else result.append("None");
        % endif
    % endfor

    result.append(")");
    return result;
}

## Abstract nodes are never instanciated directly.
% if cls.is_ptr and not cls.abstract:
    static inline ${cls.name()}* ${cls.name()}_new() {
        ${cls.name().lower()}_counter++;
        return new ${cls.name()};
    }
% endif

% if not cls.is_ptr:
    ${cls.name()} nil_${cls.name()};
% endif

std::string ${cls.name()}::__name() { return "${cls.repr_name()}"; }

% if not cls.abstract:
    ASTNode *${cls.name()}::lookup_children(const SourceLocation &sloc)
    {
        assert(sloc_range_.compare(sloc) == IN);

        /* Look for a child node that contains SLOC (i.e. return the most
           precise result).  */
        % for i, (field_type, field) in enumerate(repr_m_to_fields):
            % if is_ast_node(field_type):
                /* Note that we assume here that child nodes are ordered so
                   that the first one has a sloc range that is before the sloc
                   range of the second child node, etc.  */
                if (${field.name} != ${field_type.nullexpr()}) {
                    auto sub_lookup = ${field.name}->lookup_relative(sloc);
                    switch (sub_lookup.first) {
                    case BEFORE:
                        /* If this is the first node, SLOC is before it, so we
                           can stop here.  Otherwise, SLOC is between the
                           previous child node and the next one...  so we can
                           stop here, too.  */
                        return this;

                    case IN:
                        return sub_lookup.second;

                    case AFTER:
                        /* SLOC is after the current child node, so see with
                           the next one.  */
                        break;
                    }
                }
            % endif
        % endfor

        return this;
    }
% endif
