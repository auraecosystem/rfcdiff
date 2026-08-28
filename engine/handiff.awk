BEGIN {
    print "<table class=\"diff-table\">"
    print "<thead><tr><th colspan=\"2\">Original Document</th><th colspan=\"2\">Revised Document</th></tr></thead>"
    print "<tbody>"
    old_cnt = 0; new_cnt = 0
}

# 1. Parse Hunk Headers (e.g., @@ -42,6 +42,8 @@)
/^@@ -[0-9]+(,[0-9]+)? \+[0-9]+(,[0-9]+)? @@/ {
    flush_hunk()
    
    # Extract starting line numbers from hunk coordinates
    match($0, /-[0-9]+/)
    left_line = substr($0, RSTART + 1, RLENGTH - 1)
    
    match($0, /\+[0-9]+/)
    right_line = substr($0, RSTART + 1, RLENGTH - 1)
    
    printf "<tr class=\"hunk-head\"><td colspan=\"4\">%s</td></tr>\n", escape_html($0)
    next
}

# 2. Accumulate Deletions (Old Side)
/^-/ {
    old_buf[++old_cnt] = escape_html(substr($0, 2))
    next
}

# 3. Accumulate Additions (New Side)
/^\+/ {
    new_buf[++new_cnt] = escape_html(substr($0, 2))
    next
}

# 4. Process Unchanged Context Lines
/^ / {
    flush_hunk()
    line_content = escape_html(substr($0, 2))
    printf "<tr class=\"ctx\"><td class=\"ln\">%d</td><td class=\"cell\">%s</td><td class=\"ln\">%d</td><td class=\"cell\">%s</td></tr>\n", \
        left_line++, line_content, right_line++, line_content
    next
}

END {
    flush_hunk()
    print "</tbody></table>"
}

# Pair up buffered deletions and additions into side-by-side <tr> rows
function flush_hunk() {
    max_rows = (old_cnt > new_cnt) ? old_cnt : new_cnt
    
    for (i = 1; i <= max_rows; i++) {
        l_num = (i <= old_cnt) ? left_line++ : ""
        l_txt = (i <= old_cnt) ? old_buf[i] : ""
        r_num = (i <= new_cnt) ? right_line++ : ""
        r_txt = (i <= new_cnt) ? new_buf[i] : ""
        
        # Determine CSS row classification (diff-del, diff-add, or diff-change)
        cell_class = (i <= old_cnt && i <= new_cnt) ? "chg" : ((i <= old_cnt) ? "del" : "add")
        
        printf "<tr class=\"%s\"><td class=\"ln\">%s</td><td class=\"left-val\">%s</td><td class=\"ln\">%s</td><td class=\"right-val\">%s</td></tr>\n", \
            cell_class, l_num, l_txt, r_num, r_txt
    }
    old_cnt = 0; new_cnt = 0
}

function escape_html(str) {
    gsub(/&/, "&amp;", str)
    gsub(/</, "&lt;", str)
    gsub(/>/, "&gt;", str)
    return str
}
