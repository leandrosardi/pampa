# update packages
sudo apt -y update
sudo apt -y upgrade
# install other required packages
sudo apt install -y net-tools
sudo apt install -y gnupg2
sudo apt install -y nginx
sudo apt install -y sshpass
sudo apt install -y xterm
sudo apt install -y bc
sudo apt install -y unzip
# move into a writable location such as the /tmp to download RVM
cd /tmp
# download RVM
curl -sSL https://get.rvm.io -o rvm.sh
# install the latest stable Rails version
cat /tmp/rvm.sh | bash -s stable --rails
# start RVM
source /usr/local/rvm/scripts/rvm
# install and run Ruby 3.1.2
rvm install 3.1.2
rvm --default use 3.1.2
ruby -v
# install git
sudo apt install -y git
# install PostgreSQL dev package with header of PostgreSQL
sudo apt-get install -y libpq-dev
# install bundler
gem install bundler -v '2.3.7'
# create the code directory
##mkdir -p ~/code
##cd ~/code
# rename existing ~/code/micro.dfyl.appending to ~/code/micro.dfyl.appending.<timestamp>
#mv micro.dfyl.appending micro.dfyl.appending.$(date +%s)
## clone the micro.dfyl.appending repo
##git clone https://github.comConnectionSphere/micro.dfyl.appending
cd ~/code/micro.dfyl.appending
# install gems
bundler update
# setup RUBYLIB environment variable
export RUBYLIB=~/code/micro.dfyl.appending
# install postgresql
sudo apt install -y postgresql postgresql-contrib
# start postgresql
sudo systemctl start postgresql.service
# show postgresql status
sudo systemctl status postgresql
# switch to postgres user
sudo -i -u postgres