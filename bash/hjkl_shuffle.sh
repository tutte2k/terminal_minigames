#!/bin/bash

WIDTH=40
HEIGHT=20

bug_x=1
bug_y=1

fruits=("🍇" "🍈" "🍉" "🍊" "🍋" "🍌" "🍍" "🥭" "🍎" "🍏" "🍐")

ghost_icon="👻"
bug_icon="🪲"
ghost_positions=()  

level=1
total_collected=0
declare -A fruit_positions

ghost_move_interval=3  
ghost_move_counter=0

generate_fruits() {
    fruit_positions=()
    for fruit in "${fruits[@]}"; do
        while :; do
            pos_x=$((RANDOM % WIDTH))
            pos_y=$((RANDOM % HEIGHT))
            if [[ -z "${fruit_positions["$pos_x,$pos_y"]}" && ($pos_x != $bug_x || $pos_y != $bug_y) ]]; then
                fruit_positions["$pos_x,$pos_y"]="$fruit" 
                break
            fi
        done
    done
}

generate_fruits
ghost_count=$level  
for ((i = 0; i < ghost_count; i++)); do
    ghost_positions+=("19,$((RANDOM % (WIDTH - 1)))") 
done

draw() {
    buffer=""
    buffer+="Level: $level\n"
    buffer+="Fruits Collected: $total_collected\n"
    
    for ((y = 0; y < HEIGHT; y++)); do
        for ((x = 0; x < WIDTH; x++)); do
            if [[ $x -eq $bug_x && $y -eq $bug_y ]]; then
                buffer+="$bug_icon" 
            elif [[ -n "${fruit_positions["$x,$y"]}" ]]; then
                buffer+="${fruit_positions["$x,$y"]}"
            elif [[ " ${ghost_positions[@]} " =~ " $x,$y " ]]; then
                buffer+="$ghost_icon"  
            else
                buffer+=" "  
            fi
            buffer+=" "  
        done
        buffer+="\n"
    done

    tput clear
    echo -e "$buffer"
}

move() {
    local old_x=$bug_x
    local old_y=$bug_y

    case $1 in
        h) ((bug_x > 0)) && ((bug_x--)) ;;  
        j) ((bug_y < HEIGHT - 1)) && ((bug_y++)) ;;  
        k) ((bug_y > 0)) && ((bug_y--)) ;; 
        l) ((bug_x < WIDTH - 1)) && ((bug_x++)) ;; 
    esac

    if [[ -n "${fruit_positions["$bug_x,$bug_y"]}" ]]; then
        unset fruit_positions["$bug_x,$bug_y"]
        total_collected=$((total_collected + 1))
    fi
}

move_ghosts() {
    ghost_move_counter=$((ghost_move_counter + 1))
    if (( ghost_move_counter < ghost_move_interval )); then
        return  
    fi
    ghost_move_counter=0  

    for i in "${!ghost_positions[@]}"; do
        IFS=',' read -r ghost_x ghost_y <<< "${ghost_positions[$i]}"

        if (( RANDOM % 3 )); then
            if [[ $ghost_x -lt $bug_x ]]; then
                ((ghost_x++))
            elif [[ $ghost_x -gt $bug_x ]]; then
                ((ghost_x--))
            fi
            
            if [[ $ghost_y -lt $bug_y ]]; then
                ((ghost_y++))
            elif [[ $ghost_y -gt $bug_y ]]; then
                ((ghost_y--))
            fi
        else
            direction=$((RANDOM % 4))
            case $direction in
                0) ((ghost_x > 0)) && ((ghost_x--)) ;;  
                1) ((ghost_y < HEIGHT - 1)) && ((ghost_y++)) ;; 
                2) ((ghost_y > 0)) && ((ghost_y--)) ;;  
                3) ((ghost_x < WIDTH - 1)) && ((ghost_x++)) ;;  
            esac
        fi

        ghost_positions[$i]="$ghost_x,$ghost_y"

        if [[ $ghost_x -eq $bug_x && $ghost_y -eq $bug_y ]]; then
            echo "A ghost got you! Game Over!"
            exit
        fi
    done
}

check_next_level() {
    if [[ ${#fruit_positions[@]} -eq 0 ]]; then
        level=$((level + 1))
        ghost_count=$level  
        ghost_positions=() 
        for ((i = 0; i < ghost_count; i++)); do
            ghost_positions+=("19,$((RANDOM % (WIDTH - 1)))")
        done
        generate_fruits 
    fi
}

while :; do
    draw
    read -rsn1 -t 0.1 input 
    move "$input" 

    move_ghosts  
    check_next_level  
done

echo "Game Over! Thank you for playing!"
