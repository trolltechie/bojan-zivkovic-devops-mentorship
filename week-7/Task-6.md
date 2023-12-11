
## Zadatak za 7. sedmicu:

Tekst zadatka se nalazi na ovom [linku](https://github.com/awsbosnia/devops-aws-mentorship-program/issues/45)
Nodejs aplikacija koju je potrebno deployati, moze se preuzeti sa ovog [linka](https://github.com/awsbosnia/devops-aws-mentorship-program/blob/main/devops-mentorship-program/03-march/week-5-140323/nodejs-simple-app/app.js)

---

Izrada se moze podijeliti u 3 segmenta:
- [1. Kreiranje EC2 instance](#1-kreiranje-ec2-instance)
  - [Proces kreiranja EC2:](#proces-kreiranja-ec2)
- [2. Deployment Nodejs simple app](#2-deployment-nodejs-simple-app)
    - [Povezivanje sa EC2 instancom](#povezivanje-sa-ec2-instancom)
    - [Instalacija nginx-a](#instalacija-nginx-a)
    - [Instalacija Git-a](#instalacija-git-a)
    - [Instalacija Node-a, npm-a i potrebnih alata](#instalacija-node-a-npm-a-i-potrebnih-alata)
    - [instalacija Node version managera](#instalacija-node-version-managera)
    - [pokretanje aplikacije](#pokretanje-aplikacije)
    - [instalacija pm2](#instalacija-pm2)
- [3. CloudWatch billing alarm](#3-cloudwatch-billing-alarm)

# 1. Kreiranje EC2 instance

Kako je u postavljenom zadatku zahtijevano, EC2 instanca koju moramo napraviti mora biti `t2.micro` tipa, koristeci AMI image `Amazon Linux 2023` i sljedece osobine:

- `name`: `ec2-ime-prezime-web-server`
- security group: `sec-group-web-server` sa otvorenim portovima `22` i `80` za sav dolazni saobracaj
- key pair name: `ime-prezime-web-server-key`
- EBS volume size: `14 GiB` `gp3`

## Proces kreiranja EC2:
Iz `Services` menija izaberemo EC2, sto nas prebacuje na EC2 Dashboard. Idemo na `Launch Instance`.
* Name: `ec2-bojan-zivkovic-web-server`
`Add additional tags` -> `Add new tag` (Key: CreatedBy; Value: Bojan Zivkovic) -> `Add new tag` (Key: Email; Value: vas@email.com)
* Application and OS Images (Amazon Machine Image): `Amazon Linux 2023 AMI`
* Instance type: `t2.micro`
* Key pair (login): `Create new key pair` -> Create key pair: (Key pair name: `bojan-zivkovic-web-server-key`; Key pair type: RSA or ED25519; Private key file format: .pem, ukoliko ce se koristiti za SSH pristup / .ppk ukoliko ce se koristiti za Win/Putty pristup). Kreiranje kljuca ce pokrenuti automatsko preuzimanje istog. Nakon zavrsetka, vracamo se tamo gdje smo stali - na izbor key paira. Izaberemo novokreirani kljuc `bojan-zivkovic-web-server-key`.
* Network settings: `Edit` 
 > * VPC: *default*; 
 > * Subnet: *default*; 
 > * `Create security group`; 
 > * Security group name: sec-group-web-server; 
 > * Description: Security grupa koristena za EC2 kod deployinga Nodejs; 
 > * Inbound Security Group Rules: 
 >      * Type: SSH; Protocol: TCP; Port range:22; Source type: Anywhere; Description: Allow SSH access from anywhere
 > `Add security group rule` 
 >      * Type: HTTP; Protocol: TCP; Port range: 80; Source type: Anywhere; Description: Allow HTTP access from anywhere.

* Configure storage: 1x `14`GiB`gp3` (prema zahtjevu zadatka)
* Advanced details (opciono): Ovdje se mogu, prema potrebi, uraditi jos neka podesavanja, kao npr. da se ubaci skripta:
  ```
  #! /bin/bash
  yum update -y
  yum install httpd -y
  service httpd start
  chkconfig httpd on
  cd /var/www/html
  echo "<html><body bgcolor="orange">
  <h1>This is WebServer 01 on $(hostname -f)</h1>
  </body></html>" > index.html
  ```

Proces kreiranja instance je time okoncan.
![Slika EC2 instance](Screenshot%20from%202023-04-07%2017-30-17.png)

# 2. Deployment Nodejs simple app

### Povezivanje sa EC2 instancom
Prije samog pocetka deploymenta, moramo obezbjediti mogucnost povezivanja. Stoga prvo pokrecemo terminal i prebacujemo se u direktorijum u kojem se nalazi preuzeti .pem kljuc iz prethodnog koraka. U konkretnom slucaju, po defaultu, kljuc je otisao u Downloads direktorijum. Prvo moramo dodijeliti mogucnost pisanja i citanja nad tim fajlom.
`$ chmod 600 *.pem`
Sljedece pokrecemo komandu za ssh pristup EC2 instanci:
`$ ssh -i bojan-zivkovic-web-server-key.pem ec2-user@3.71.4.168` (defaultni user svake Amazon Linux instance je ec2user, a 3.71.4.168 je javna IP adresa nase EC2 instance)
Na `Are you sure you want to continue connecting?`, odgovorite sa Yes. Konektovani samo na instancu. Mozemo otpoceti korake za deployment.

### Instalacija nginx-a
`$ sudo su -` - prebacujemo se na root usera
`$ yum install nginx -y` - pokrecemo instalaciju nginx-a
`$ systemctl nginx start` - pokrecemo nginx
`$ systemctl enable nginx` - obeybjedjujemo pokretanje nginx-a prilikom boot-anja
`$ cd /etc/nginx/conf.d` - premjestamo se u conf.d direktorijum
`$ sudo touch node-app.conf` - kreiramo konfiguracioni fajl za node aplikaciju
`$ sudo nano node-app.conf` - otvaramo fajl u editoru kako bismo unijeli podesavanja:
```
server {
  listen 80;
  server_name 3.71.4.168/; # public ip adresa

  location / {
    proxy_pass http://127.0.0.1:8008; # localhost 127.0.0.1 na portu 8008 kako je navedeno u app konfiguraciji
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}
```
`$sudo systemctl restart nginx` - resetujemo nginx kako bi primjenio nova podesavanja
`$ systemctl status nginx` - provjera stanja nginx-a (alternativno moze i sa `$ ps aux | grep nginx`)

### Instalacija Git-a
Prvo je potrebno generisati kljuceve, te stoga prvo kucamo:
`$ ssh-keygen -t rsa`
Prelazimo u `.ssh` direktorijum.
`$ ssh-keygen -t rsa`  - generisemo par kljuceva
`$ cat id_rsa.pub` - iscitamo sadrzaj kljuca, te sadrzinu kopiramo na nas GitHub profil, pod nazivom `ec2-instance-amazon-linux`
`$ sudo yum install git -y` - instalisemo Git na instanci
Kopiramo Nodejs aplikaciju sa GitHub profila (git@github.com:awsbosnia/devops-aws-mentorship-program.git)

### Instalacija Node-a, npm-a i potrebnih alata
`$ curl -L -o nodesource_setup.sh https://rpm.nodesource.com/setup_14.x` - preuzimanje Node.js instalacije
`$ sudo bash nodesource_setup.sh` - pokretanje instalacione skripte
`$ sudo yum install -y nodejs` - Pokretanje instalacije Node-a
`$ node -v` - provjera instalisane verzije
`$ sudo yum install -y gcc++ make`  - instalisanje c++ kompajlera

### instalacija Node version managera
`$ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash` - preuzimanje nvm instalacije
`$ . ~/.nvm/nvm.sh` - pokretanje skripte
`$ nvm install --lts` - instalisanje nvm-a
`$ node -e "console.log('Running Node.js ' + process.version)"` - provjera instalisane verzije

### pokretanje aplikacije
`$ cd nodejs-simple-app` - ulazak u direktorijum
`$ ls` - izlistavamo sadrzaj i trazimo server.js fajl
`$ npm install` - instalacija Node package managera
`$ node app.js` - pokrecemo aplikaciju
`$ ps aux | grep node` - provjeravamo da li je aplikacija pokrenuta. Ispostavice se da nije.
`$ node server.js` - ukoliko se ni nakon ovoga aplikacija ne prikazuje na portu 8008, potrebno je instalisati pm2

### instalacija pm2
`$ npm install -g pm2` - instalacija proces managera
`$ pm2 start server.js` - pokretanje Node.js aplikacije

![Screenshot pristupa](/Screenshot%20from%202023-04-07%2017-29-16.png)
Deployment uspjesan, aplikacija radi.

# 3. CloudWatch billing alarm

Za kreiranje alarma moramo se prebaciti na `us-east-1` regiju (N. Virginia) jer su tamo sacuvane metrike za obracune.
Biramo `CloudWatch` -> `Alarms` -> `Billing` -> `Create alarm`


**Specify metric and conditions**
> **Notification**
> Metric: `Select metric` -> `Billing` -> `Total estimated charge` -> [x]USD -> `Graphed metrics`: Statistic: Maximum; Period: 6 hours -> `Select metric`
Metric name: `cw-cost-alert-bojan-zivkovic`
Currency:`USD`
Treshold type: [x]Static
Whenever cw-costalert-bojan-zivkovic is...: [x]Greater
than...:`5` USD
-> `Next`

**Configure action**
> Alarm state trigger: [x]In alarm
> Send a notification to the following SNS topic: [x]Create new topic
> Email endpoints that will receive the notification...: `vas@email.com`
> `Create topic`
> -> `Next`

**Add name and description**
> Alarm name: `cw-cost-alert-bojan-zivkovic`
> -> `Next`

**Preview and create**
> -> `Create alarm`

![CloudWatch kontrola troskova](Screenshot%20from%202023-04-07%2017-31-49.png)

Nakon ovoga potrebno je potvrditi pretplatu na mailu koji je naveden u procesu kreiranja. Da bi se dobijale notifikacije i prekoracenju troskova u ovom alarmu, kreiramo SNS (Simple Notification Service). 