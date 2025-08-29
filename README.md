# File Mapper
## Usage
`awk -f filemapper.awk rule.fm`

## Explain
rule.fm is a plain text, format:
```
# This is a comment. Must begin with "# ".
# Comments in line are not supported.

path/to/src/#??#_file : out/#??#_dst/file
# This line declare the file src and dst.
# The separator is ":" with at least one [space].
# pattern "#??#" will be replaced as below.
# could be multiple lines, allows you to map the similar path.

file_src1 - file_dst1
# Separator is "-" with at least one [space].
# The left part will replace the src's "#??#",
# and the right part will replace the dst's.
# This would also copy the final src to final dst.

file_src2 - file_dst2
# same.

- file_dst3
# If the left part is empty,
# this will link the last final_dst to this-line's final dst.
# The link is soft and relative.
# link to file_dst2

- file_dst4
# link to file_dst2 to avoid link chain.

# And you can create another map rule below.
# The different unit can in the same file.
```

### Content tree:
before:
```
$ tree
.
├── path
│   └── to
│       └── src
│           ├── file_src1_file
│           └── file_src2_file
└── rule.fm

4 directories, 3 files
```
after:
```
$ tree
.
├── out
│   ├── file_dst1_dst
│   │   └── file
│   ├── file_dst2_dst
│   │   └── file
│   ├── file_dst3_dst
│   │   └── file -> ../file_dst2_dst/file
│   └── file_dst4_dst
│       └── file -> ../file_dst2_dst/file
├── path
│   └── to
│       └── src
│           ├── file_src1_file
│           └── file_src2_file
└── rule.fm

9 directories, 7 files
```

If you want to see what will happen without any changes, just commenting line 112 and 132 (`system(x)`). Only print the command without execution.
