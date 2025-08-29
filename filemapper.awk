function is_array_empty(array) {
    for (key in array) {
        return 0;
    }
    return 1;
}

function unquote(str) {
    if ((substr(str, 1, 1) == "\"" && substr(str, length(str), 1) == "\"") || \
        (substr(str, 1, 1) == "'" && substr(str, length(str), 1) == "'")) {
        return substr(str, 2, length(str) - 2);
    }
    return str;
}

function quote_if_needed(str, should_quote) {
    if (should_quote) {
        return "\"" str "\"";
    }
    return str;
}

function is_quoted(str) {
    return (substr(str, 1, 1) == "\"" && substr(str, length(str), 1) == "\"") || \
           (substr(str, 1, 1) == "'" && substr(str, length(str), 1) == "'");
}

function get_relative_path(src, dst,   src_parts, dst_parts, n, m, common_len, i, up_levels, relative_path) {
    if (substr(src, length(src)) == "/") { src = substr(src, 1, length(src)-1) }
    if (substr(dst, length(dst)) == "/") { dst = substr(dst, 1, length(dst)-1) }

    if (substr(src, 1, 1) != "/") { src = "./" src }
    if (substr(dst, 1, 1) != "/") { dst = "./" dst }

    n = split(src, src_parts, "/");
    m = split(dst, dst_parts, "/");

    common_len = 0;
    for (i = 1; i <= n && i <= m; i++) {
        if (src_parts[i] == dst_parts[i]) {
            common_len++;
        } else {
            break;
        }
    }

    up_levels = m - common_len -1;
    relative_path = "";
    for (i = 1; i <= up_levels; i++) {
        relative_path = relative_path "../";
    }

    for (i = common_len + 1; i <= n; i++) {
        relative_path = relative_path src_parts[i];
        if (i < n) {
            relative_path = relative_path "/";
        }
    }
    
    return relative_path;
}

BEGIN {
    path_array_src[0] = "";
    delete path_array_src[0];
    path_array_dst[0] = "";
    delete path_array_dst[0];
    
    pattern_array_src[0] = "";
    delete pattern_array_src[0];
    pattern_array_dst[0] = "";
    delete pattern_array_dst[0];
    
    path_count = 0;
    pattern_count = 0;
    last_non_empty_dst = "";
}

function process_files() {
    for (i = 1; i <= path_count; i++) {
        path_src = path_array_src[i];
        path_dst = path_array_dst[i];
        
        for (j = 1; j <= pattern_count; j++) {
            pattern_src = pattern_array_src[j];
            pattern_dst = pattern_array_dst[j];

            src_was_quoted = is_quoted(path_src);
            dst_was_quoted = is_quoted(path_dst);
            pattern_src_was_quoted = is_quoted(pattern_src);
            pattern_dst_was_quoted = is_quoted(pattern_dst);
            
            src_str = unquote(path_src);
            dst_str = unquote(path_dst);
            pattern_src_str = unquote(pattern_src);
            pattern_dst_str = unquote(pattern_dst);
            
            final_src = src_str;
            final_dst = dst_str;
            
            gsub(/#\?\?#/, pattern_dst_str, final_dst);
            
            if (final_dst !~ /\//) {
                dst_dir = ".";
            } else {
                dst_dir = final_dst;
                sub("/[^/]*$", "", dst_dir);
            }
            
            mkdir_cmd = "mkdir -p \"" dst_dir "\"";
            print "CMD: " mkdir_cmd;
            system(mkdir_cmd);
            
            cmd = "";

            if (pattern_src_str == "") {
                if (last_non_empty_dst == "") {
                    print "Error: No previous destination for empty pattern source";
                    continue;
                }
                
                final_src = unquote(last_non_empty_dst);
                relative_src = get_relative_path(final_src, final_dst);
                cmd = "ln -sf \"" relative_src "\" \"" final_dst "\"";
                
            } else {
                gsub(/#\?\?#/, pattern_src_str, final_src);
                cmd = "cp -r \"" final_src "\" \"" final_dst "\"";
            }
            
            print "CMD: " cmd;
            system(cmd); 

            if (pattern_src_str != "") {
                last_non_empty_dst = final_dst;
            }

            output_src = quote_if_needed(final_src, src_was_quoted || pattern_src_was_quoted);
            output_dst = quote_if_needed(final_dst, dst_was_quoted || pattern_dst_was_quoted);
        }
    }
}

{
    # 忽略注释和空行
    if ($0 ~ /^[ \t]*#|^[ \t]*$/) {
        next;
    }
    
    is_path_matched = 0;
    is_pattern_matched = 0;
    in_quote = 0;
    split_pos = 0;
    for (i = 1; i <= length($0); i++) {
        char = substr($0, i, 1);
        if (char == "\"") {
            in_quote = !in_quote;
        }
        if (in_quote == 0) {
            if (char == ":") {
                is_space_before = (i > 1 && (substr($0, i - 1, 1) ~ /[ \t]/));
                is_space_after = (i < length($0) && (substr($0, i + 1, 1) ~ /[ \t]/));
                if (is_space_before || is_space_after) {
                    is_path_matched = 1;
                    split_pos = i;
                    break;
                }
            } else if (char == "-") {
                is_space_before = (i > 1 && (substr($0, i - 1, 1) ~ /[ \t]/));
                is_space_after = (i < length($0) && (substr($0, i + 1, 1) ~ /[ \t]/));
                if (is_space_before || is_space_after) {
                    if (is_path_matched == 0) {
                        is_pattern_matched = 1;
                        split_pos = i;
                        break;
                    }
                }
            }
        }
    }
    if (is_path_matched) {
        if(!is_array_empty(pattern_array_src)) {
            process_files();
            delete path_array_src;
            delete path_array_dst;
            delete pattern_array_src;
            delete pattern_array_dst;
            
            path_count = 0;
            pattern_count = 0;
        }
        key = substr($0, split_pos + 1);
        value = substr($0, 1, split_pos - 1);
        gsub(/^[ \t]+|[ \t]+$/, "", key);
        gsub(/^[ \t]+|[ \t]+$/, "", value);
        
        path_count++;
        path_array_src[path_count] = value;
        path_array_dst[path_count] = key;
    } else if (is_pattern_matched) {
        key = substr($0, split_pos + 1);
        value = substr($0, 1, split_pos - 1);
        gsub(/^[ \t]+|[ \t]+$/, "", key);
        gsub(/^[ \t]+|[ \t]+$/, "", value);
        
        pattern_count++;
        pattern_array_src[pattern_count] = value;
        pattern_array_dst[pattern_count] = key;
    }
}

END {
    if(!is_array_empty(path_array_src) && !is_array_empty(pattern_array_src)) {
        process_files();
    }
}