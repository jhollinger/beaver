require 'yaml'
require 'time'

module Beaver
  # Sundry utility methods for use by Beaver
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
                s << COLIN if str[i,1] =~ LETTER_REGEX
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
            if state == :val
              state = :escape
              next
            end
        end

        case state
          when :key, :val, :val_array
            s << c
          when :escape
            s << c
            state = :val
          when :val_array_end
            s << c << "\n"
            state = :pre_key
        end
      end
      YAML.load s
    end

    # Returns an array of arrays of strings with all the columns padded the same length.
    def self.tablize(rows)
      max_sizes = rows.inject([0]*rows.first.size) do |sizes, vals|
        vals.map! &:to_s
        vals.each_with_index { |val, i| sizes[i] = val.size if val.size > sizes[i] }; sizes
      end
      rows.map { |vals| vals.each_with_index.map { |val, i| val.to_s.ljust(max_sizes[i]) } }
    end

    # Parse a string (from a command-line arg) into a Date object
    def self.parse_date(date)
      case date
        when /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ then Date.parse(date)
        when /^-\d+$/ then Date.today + date.to_i
        else nil
      end
    end
  end
end
