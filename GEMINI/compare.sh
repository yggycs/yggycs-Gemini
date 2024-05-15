# Function: compare the best arch found in DSE and Simba arch with our mapping and Tangram mapping methods.
# Usage: ./compare.sh <best_arch_file> [output_folder]

run() {
    echo "[INFO] Comparison experiment starts."
    start_time=$(date +%s)
    read -r line < $1
    best_arch=($line)
    # Common parameters.
    mm=${best_arch[0]}
    ff=${best_arch[4]}
    tops=${best_arch[12]}

    for nn in ${dnn_range[*]}
    do
        temp_path0=$output_path/${network[$nn]}
        mkdir $temp_path0
        for batch in ${batch_range[*]}
        do
        {   
            temp_path1=$temp_path0/batch_$batch
            mkdir $temp_path1
            # Best arch parameters.
            xx=${best_arch[1]}
            yy=${best_arch[2]}
            ss=${best_arch[3]}
            xcut=${best_arch[5]}
            ycut=${best_arch[6]}
            nop=${best_arch[7]}
            ddr=${best_arch[8]}
            noc=${best_arch[9]}
            mac=${best_arch[10]}
            ul3=${best_arch[11]}
            echo "$mm $nn $xx $yy $ss $batch $iter_rnd $ff $xcut $ycut $nop $ddr $noc $mac $ul3 $tops" | ./build/stschedule $temp_path1/$out_log > /dev/null
            # Simba arch parameters.
            xx=6
            yy=6
            ss=6
            xcut=6
            ycut=6
            nop=13
            ddr=`expr 2 \* $tops`
            noc=13
            mac=1024
            ul3=1024
            echo "$mm $nn $xx $yy $ss $batch $iter_rnd $ff $xcut $ycut $nop $ddr $noc $mac $ul3 $tops" | ./build/stschedule $temp_path1/$out_log > /dev/null
        } & # Multi-process.
        done
    done
    wait
    end_time=$(date +%s)
    search_time=$(( end_time - start_time ))
    _second=`expr $search_time % 60`
    _minute=`expr $search_time / 60`
    _hour=`expr $_minute / 60`
    _minute=`expr $_minute % 60`
    echo "[INFO] Experiment time: $_hour h $_minute m $_second s ($search_time)seconds."
}

statistics() {
    echo "[INFO] Analysation starts."
    # Optimization statistics.
    if [ -f $output_path/$result_log ]; then
        rm $output_path/$result_log
    fi
    touch $output_path/$result_log
    if [ -f $output_path/$compare_log ]; then
        rm $output_path/$compare_log
    fi
    touch $output_path/$compare_log
    gg_st_energy_rate=1
    gg_st_delay_rate=1
    gg_sg_energy_rate=1
    gg_sg_delay_rate=1
    for batch_idx in `seq 0 1 $(( ${#batch_range[*]} - 1))`
    do
        batch=${batch_range[$batch_idx]}

        for sub_dir in `ls $output_path`
        do  
            if [ ! -d $output_path/$sub_dir ]; then
                continue;
            fi
            if [ ! -f $output_path/$sub_dir/batch_$batch/$out_log ]; then
                echo "[ERROR] File $output_path/$sub_dir/batch_$batch/$out_log doesn't exsit. Script exit."
                exit
            fi
            i=0
            while read line
            do
                if [ -z "$line" ]; then
                    # Blank line.
                    echo blank line.
                    break
                fi
                record=($line)
                case $i in
                0) # G-Arch with T-Mapping
                    # Pass.
                    ;;
                1) # G-Arch with G-Mapping
                    gg_energy=${record[17]}
                    gg_delay=${record[18]}
                    echo $line >> $output_path/$compare_log
                    ;;
                2) # S-Arch with T-Mapping
                    gg_st_energy_rate=`echo "scale=18; $gg_st_energy_rate * ((1 / $gg_energy) - (1 / ${record[17]})) * ${record[17]}" | bc`
                    gg_st_delay_rate=`echo "scale=18; $gg_st_delay_rate * ((1 / $gg_delay) - (1 / ${record[18]})) * ${record[18]}" | bc`
                    echo $line >> $output_path/$compare_log
                    ;;
                3) # S-Arch with G-Mapping
                    gg_sg_energy_rate=`echo "scale=18; $gg_sg_energy_rate * ((1 / $gg_energy) - (1 / ${record[17]})) * ${record[17]}" | bc`
                    gg_sg_delay_rate=`echo "scale=18; $gg_sg_delay_rate * ((1 / $gg_delay) - (1 / ${record[18]})) * ${record[18]}" | bc`
                    echo $line >> $output_path/$compare_log
                    ;;
                *)
                    echo "[ERROR] $output_path/$sub_dir/batch_$batch/$out_log is supposed to have 4 non blank rows only."
                    exit
                esac
                (( i++ ))
            done < $output_path/$sub_dir/batch_$batch/$out_log
        done
    done
    exponent=`echo "scale=8; 1.0 / (${#dnn_range[*]} * ${#batch_range[*]})" | bc`
    gg_st_energy_rate=$(python3 -c "print(100 * ($gg_st_energy_rate ** $exponent))")
    gg_st_delay_rate=$(python3 -c "print(100 * ($gg_st_delay_rate ** $exponent))")
    gg_sg_energy_rate=$(python3 -c "print(100 * ($gg_sg_energy_rate ** $exponent))")
    gg_sg_delay_rate=$(python3 -c "print(100 * ($gg_sg_delay_rate ** $exponent))")

    # Monetary cost comparison.
    line_g_arch=`sed -n "1p" $output_path/$compare_log`
    line_s_arch=`sed -n "2p" $output_path/$compare_log`
    line=($line_g_arch)
    g_cost=${line[16]}
    line=($line_s_arch)
    s_cost=${line[16]}
    mc_rate=`echo "scale=8; ($g_cost - $s_cost) / $s_cost" | bc`

    echo "------------ Comparison Result ------------" >> $output_path/$result_log
    printf "G-Arch with G-Mapping improves %6.3f%% energy efficiency over Simba Arch with T-Mapping on average.\n" $gg_st_energy_rate >> $output_path/$result_log
    printf "G-Arch with G-Mapping improves %6.3f%% performance over Simba Arch with T-Mapping on average.\n" $gg_st_delay_rate >> $output_path/$result_log
#    printf "G-Arch with G-Mapping improves %6.3f%% energy efficiency over Simba Arch with G-Mapping on average.\n" $gg_sg_energy_rate >> $output_path/$result_log
#    printf "G-Arch with G-Mapping improves %6.3f%% performance over Simba Arch with G-Mapping on average.\n" $gg_sg_delay_rate >> $output_path/$result_log
    printf "G-Arch costs %6.3f%% more money over Simba Arch.\n" $mc_rate >> $output_path/$result_log
    cat $output_path/$result_log
    echo "[INFO] Analysation accomplishes."
}

if [ $# -lt 1 ]; then
    echo "Usage: ./compare.sh <best_arch>"
    exit
fi
if [ $# -gt 1 ]; then
    output_path=`readlink -f $2`
else
    temp_date=$(date "+%Y_%m_%d_%H_%M_%S")
    if [ ! -d "compare_log" ]; then
        mkdir "compare_log"
    fi
    output_path=`pwd`/compare_log/${temp_date}
fi
if [ ! -d $output_path ]; then
    echo Making output foler $output_path.
    mkdir $output_path
fi

out_log=result.log
compare_log=compare.log
compare_csv=compare.csv
compare_xlsx=compare.xlsx
result_log=comparison_result.log

network=(darknet19 vgg resnet50  googlenet resnet101 densenet  ires gnmt lstm  zfnet transformer transformer_cell  pnasnet resnext50 resnet152)
headers="mm,nn,xx,yy,ss,bb,rr,ff,xcut,ycut,nop,ddr,noc,mac,ul3,tops,cost_overall,energy,cycle,edp,cost,idx,ubuf,buf,bus,mac,NoC,NoP,DRAM,compute_die_area,IO_die_area,os_area,cost_compute,cost_IO,cost_os_overall,cost_soc"

# Config
iter_rnd=150
batch_range=(1 64)
dnn_range=(2 6 11 12 13)

echo "**************** Comparison Experiment ****************"
run $1
statistics
echo "[INFO] Experiment log has been writed into $output_path/$compare_log."
echo "[INFO] Optimization rate has been writed into $output_path/$result_log."
echo "[INFO] File format converting..."
python3 ./pyscripts/log2csv.py $output_path/$compare_log $output_path/$compare_csv
sed "1i\\$headers" -i $output_path/$compare_csv
python3 ./pyscripts/csv2xlsx.py $output_path/$compare_csv $output_path/$compare_xlsx
echo "**************** Experiment Terminates ****************"
