#!/bin/bash

figlet  "The Magician" -c

echo "Enter Domain name"
read domain
echo "Your domain is :  $domain"

echo "Tool: sublist3r is running"
python3 sublist3r.py -d $domain -o sublister.txt

echo "Tool: Subfinder is running"
subfinder -d $domain --all -o subfinder.txt

echo "Tool: Assetfinder is running"
assetfinder -subs-only $domain | tee -a assetfinder.txt

echo "Tool: Finddomain is running"
findomain -t $domain -u find.txt

echo "Tool:  chaos is running"
chaos -d $domain -o chaos.txt

cat *.txt | sort -u | tee -a all.txt
rm  sublister.txt subfinder.txt assetfinder.txt find.txt chaos.txt

echo "Tool:  dnsx is running"
cat all.txt | dnsx -o dnsx.txt

rm all.txt

echo "Tool:  subdomains permutation, alterx is running"
cat dnsx.txt | alterx -o alldomains.txt

echo "Tool:  dnsx is running again after permutation"
cat alldomains.txt | dnsx -o subdomains.txt

rm dnsx.txt alldomains.txt

figlet  "Subdomain Enumuration completed Now It will run httpx soon" -c

mkdir nuclei_output
mkdir parameters
mkdir ports

echo "HTTPX is running part 1 no detail"
cat subdomains.txt | httpx --random-agent -fc 400,404 -o alive.txt

echo "HTTPX is running part 2 detail information"
cat subdomains.txt | httpx --random-agent --status-code --title -server -td -cl -fc 400,404 -o httpx_detail_sub.txt

figlet  "Now its Running Nuclei tool" -c

nuclei -up
nuclei -ut

echo "Nuclei is running Low severity template"
nuclei -l alive.txt -t /root/nuclei-templates/ -severity low -o nuclei_output/low.txt
sleep 120s

echo "Nuclei is running Medium severity template"
nuclei -l alive.txt -t /root/nuclei-templates/ -severity medium -o nuclei_output/medium.txt
sleep 120s

echo "Nuclei is running High severity template"
nuclei -l alive.txt -t /root/nuclei-templates/ -severity high -o nuclei_output/high.txt
sleep 120s

echo "Nuclei is running Critical severity template"
nuclei -l alive.txt -t /root/nuclei-templates/ -severity critical -o nuclei_output/critical.txt
sleep 120s

echo "Nuclei is running Low severity template"
nuclei -l alive.txt -t /root/nuclei-templates/ -severity info -o nuclei_output/info.txt
sleep 120s 


echo "gau is running"
cat alive.txt | gau --blacklist png,jpg,gif,jpeg,swf,woff,gif,svg --o gau.txt

echo "katana is running"
katana -list alive.txt -silent -d 6 -rl 25 -jc -f qurl -o katana.txt

echo "Finding parameter form web archive"
cat gau.txt katana.txt | grep "?" | uro | httpx -silent > parameters.txt


echo "Nuclei is running fuzzing templete"
nuclei -l parameters.txt -t /root/nuclei-templates/dast/ -dast -o nuclei_output/nuclei.txt
sleep 120s

echo "Using gf Tool to find parameter"

cat parameters.txt | gf xss | sed "s/'/ /g" | sed "s/(/ /g" | sed "s/)/ /g" | qsreplace "FUZZ" | anew -q parameters/xss.txt
cat parameters.txt | gf lfi | sed "s/'/ /g" | sed "s/(/ /g" | sed "s/)/ /g" | anew -q parameters/lfi.txt
cat parameters.txt | gf ssrf | sed "s/'/ /g" | sed "s/(/ /g" | sed "s/)/ /g" | anew -q parameters/ssrf.txt
cat parameters.txt | gf ssti | sed "s/'/ /g" | sed "s/(/ /g" | sed "s/)/ /g" | anew -q parameters/ssti.txt
cat parameters.txt | gf sqli | sed "s/'/ /g" | sed "s/(/ /g" | sed "s/)/ /g" | anew -q parameters/sqli.txt
cat parameters.txt | gf redirect | sed "s/'/ /g" | sed "s/(/ /g" | sed "s/)/ /g" | anew -q parameters/redirect.txt

echo "Running port scanning"
naabu -list subdomains.txt -p - -exclude-ports 80,443 -exclude-cdn -nmap-cli 'nmap -sV -sC -Pn -oN ports/nmap.txt'
