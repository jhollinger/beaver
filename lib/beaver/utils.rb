require 'yaml'

module Beaver
  module Utils
    LBRACE, RBRACE = '{', '}'
    LBRACKET, RBRACKET = '[', ']'
    QUOTE = '"'
    ESCAPE = '\\'
    EQUAL = '='
    COLIN = ':'
    TO_SPACE = ['>']
    SPACE = ' '
    COMMA = ','
    LETTER_REGEX = /^[a-z]$/i

    # Converts a string representation of a Hash into YAML, then into a Hash.
    # This is targeted towards the Parameters value in Rails logs. It is assumed that every key is a represented as a String in the logs.
    # All keys, except for numeric keys, will be converted to Symbols.
    def self.str_to_hash(str)
      s = ''
      indent = 0
      state = :pre_key
      i = 0
      str.each_char do |c|
        i += 1
        case c
          when QUOTE
            case state
              when :pre_key
                s << (SPACE * indent)
                s << ':' if str[i] =~ LETTER_REGEX
                state = :key
                next
              when :key
                s << COLIN << SPACE
                state = :pre_val
                next
              when :pre_val, :escape
                state = :val
                next
              when :val
                state = :pre_key
                s << "\n"
                next
            end
          when LBRACE
            case state
              # Hash as a value, starting a new indent level
              when :pre_val
                state = :pre_key
                indent += 2
                s << "\n"# << (SPACE * indent)
                next
              when :pre_key
                next
            end
          when RBRACE
            case state
              when :pre_key
                indent -= 2 if indent > 0
            end
          when LBRACKET
            case state
              when :pre_val
                state = :val_array
            end
          when RBRACKET
            case state
              when :val_array
                state = :val_array_end
            end
          when ESCAPE
            state = :escape if state == :val
        end

        case state
          when :key, :val, :val_array, :escape
            s << c
          when :val_array_end
            s << c << "\n"
            state = :pre_key
        end
      end
      YAML.load s
    end
  end
end
