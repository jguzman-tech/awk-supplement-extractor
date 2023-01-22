#!/bin/bash

function extract() {
    local file
    file='examples.index'
    [[ -n "$1" ]] && file="$1"
    awk -v f="$file" '$1 == f { print substr($0, length($1)+2) }' \
        <<< "$OUTPUT"
}

function setup() {
    tput smcup # save initial cursor position
    stty -echo # hide all user input
    tput civis # hide cursor

    LINES="$(tput lines)"
    COLS="$(tput cols)"
}

function cleanup() {
    # restore terminal state
    tput rmcup
    stty echo
    tput cnorm
    exit
}

function mvselect() {
    tput clear
    tput cup 0 0
    awk -v start="$2" -v end="$3" -v select="$4" \
        'NR >= start+1 && NR <= end+1 {
           if(NR == select+1) {
             printf "\x1b[41m"$0"\x1b[0m\n"
           }
           else {
             print
           }
         }' \
        <<< "$1"

    # highlight a line
    tput cup "$4" 0
    tput rev
    tput cup "$4" "40"
    tput sgr0
    
    tput cup $((LINES-1)) 0
    echo -n "$(tput rev)Use arrow keys and <ENTER> to select a file$(tput sgr0)"
    tput cup $((LINES-1)) 0
}

function fmvselect() {
    tput clear
    tput cup 0 0
    awk -v start="$2" -v end="$3" \
        'NR >= start+1 && NR <= end+1;' \
        <<< "$1"

    # highlight a line
    tput cup "$4" 0
    tput rev
    tput cup "$4" "40"
    tput sgr0
    
    tput cup $((LINES-1)) 0
    echo -n "$(tput rev)Press 'y' to extract file in cwd or 'n' to go back to '\
the menu$(tput sgr0)"
    tput cup $((LINES-1)) 0
}

function menu() {
    local content
    local start
    local end

    content="$(extract)"

    start=0
    end=$((LINES-1))
    if [[ -n "$1" ]]; then
        select=$(awk -v section="$1" \
                     '(substr($2, 1, length(section)) == section) {
                         print NR-1; exit
                      }' \
                     <<< "$content")
        start=$((select-9))
        end=$((start+LINES-1))
    else
        select=9
    fi
    len="$(wc -l <<< "$content")"
    
    tput smcup
    mvselect "$content" "$start" "$end" "$select"

    while :; do
        LC_CTYPE=C read -r -N 1
        case "$REPLY" in
            $'\x1b')
                # possible arrow key press
                LC_CTYPE=C read -r -N 2
                case "$REPLY" in
                    $'\x5b\x41')
                        # up
                        if [[ "$select" -gt 9 ]]; then
                            select=$((select-1))
                            start=$((start-1))
                            end=$((end-1))
                            mvselect "$content" "$start" "$end" "$select"
                        fi
                        ;;
                    $'\x5b\x42')
                        # down
                        if [[ "$select" -lt "$((len-1))" ]]; then
                            select=$((select+1))
                            start=$((start+1))
                            end=$((end+1))
                            mvselect "$content" "$start" "$end" "$select"
                        fi
                        ;;
                esac
                ;;
            $'\x0a')
                # enter key press
                file=$(awk -v x="$((select+1))" 'NR == x { print $1 }' \
                           <<< "$content")
                buffer="$(extract "$file")"

                fstart=0
                flen="$(wc -l <<< "$buffer")"
                fend=$((LINES-1))
                
                tput clear
                tput cup 0 0
                echo "$buffer" | head -n $((LINES-2))
                tput cup $((LINES-1)) 0
                echo -n "$(tput rev)Press 'y' to extract file in cwd or 'n' to'\
 go back to the menu$(tput sgr0)"
                while LC_CTYPE=C read -r -N 1; do
                    case "$REPLY" in
                        $'\x1b')
                            # possible arrow key press
                            LC_CTYPE=C read -r -N 2
                            case "$REPLY" in
                                $'\x5b\x41')
                                    # up
                                    if [[ "$fstart" -gt 0 ]]; then
                                        fstart=$((fstart-1))
                                        fend=$((fend-1))
                                        fmvselect "$buffer" "$fstart" "$fend"
                                    fi
                                    ;;
                                $'\x5b\x42')
                                    # down
                                    if [[ "$fend" -lt "$flen" ]]; then
                                        fstart=$((fstart+1))
                                        fend=$((fend+1))
                                        fmvselect "$buffer" "$fstart" "$fend"
                                    fi
                                    ;;
                            esac
                            ;;
                        y|Y)
                            :
                            if cat > "$file" <<< "$buffer"; then
                                tput cup $((LINES-1)) 0
                                printf '%'"$COLS"'s'
                                tput rev
                                echo -n "Wrote '$flen' lines to ./$file"
                                tput sgr0
                                sleep 2
                            else
                                tput cup $((LINES-1)) 0
                                echo -n "$(tput rev)ERROR: unable to write to \
file '$file', do you have write permissions in the current directory?\
$(tput sgr0)"
                            fi
                            mvselect "$content" "$start" "$end" "$select"
                            break
                            ;;
                        n|N)
                            mvselect "$content" "$start" "$end" "$select"
                            break
                            ;;
                    esac
                done
                ;;
            *)
                : # ignore other keys for now
                ;;
        esac
    done
    cleanup
}

#### GLOBALS ####

export OUTPUT
export OLDSTTY
export LINES
export COLS

#### MAIN ####

[[ -n "$1" ]] && section="$1"

datafile="$(realpath "$(dirname "${BASH_SOURCE[0]}")")/awkcode.txt"
[[ ! -f "$datafile" ]] && {
    echo "ERROR: '$datafile' does not exist" 1>&2
    exit 1
}
OUTPUT="$(cat "$datafile")"

if [[ -t 0 && -t 1 ]]; then
    # we are in an interactive shell

    # cleanup these TUI settings when user hits C-c
    trap cleanup SIGINT
    
    # not sure why this one is necessary, may be due to my read commands
    trap 'stty echo' EXIT
    
    setup
    menu "$section"
    cleanup
else
    echo "ERROR: must be in an interactive shell" 1>&2
fi
