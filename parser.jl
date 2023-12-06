function parse_file(filename::String)
    file = open(filename)
    lines = readlines(file)
    close(file)
    return parse_lines(lines)
end