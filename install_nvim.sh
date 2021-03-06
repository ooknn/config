#!/bin/bash
set -x
export SUDO="sudo"
export InstallCommand="default"
export ToolsDir="$HOME/.config/dotfiles"
export BinaryDir="$HOME/bin"
export DotfilesDir=$PWD
BasePath=$(cd `dirname $0`; pwd)
create_binary_dir()
{
    if [ ! -d ${BinaryDir} ]; then
        mkdir -p ${BinaryDir}
    fi
}

create_tools_dir()
{
    if [ ! -d ${ToolsDir} ]; then
        mkdir -p ${ToolsDir}
    fi
}
update_sudo()
{

    if [[ $(id -u) -eq 0 ]];then
        export SUDO=""
    else
        export SUDO="sudo"
    fi
}

update_install_command()
{
    export OS_NAME=$( cat /etc/os-release | grep ^NAME | cut -d'=' -f2 | sed 's/\"//gI' )    
    case "$OS_NAME" in    
      "CentOS Linux")    
        export OsName="centos"
        export InstallCommand=" ${SUDO} yum install -y "
        ${InstallCommand} epel-release
      ;;    
      "Ubuntu")    
        export OsName="ubuntu"
        export InstallCommand=" ${SUDO} apt-get install -y "
        ${SUDO} apt-get update
      ;;    
      *)    
    esac
}

curl_proxy="curl -x socks5://192.168.2.105:1080"
Pip3Install="pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple"

ubuntu_install_prepare_software()
{
    ${InstallCommand} curl git wget libssl-dev
    ${InstallCommand} zlib1g-dev libtinfo-dev 
    ${InstallCommand} build-essential python-dev python3-dev  
    ${InstallCommand} python3-pip ruby rubygems tig htop tmux lua5.1
    ${InstallCommand} python-setuptools python3-setuptools
    ${InstallCommand} ruby rubygems tig htop tmux lua5.1
    ${Pip3Install} neovim jedi  pylint 
    ${SUDO} ln -sf `which python3` /usr/local/bin/python3
    ${SUDO} gem install coderay rouge
}



install_vim_plug()
{
    $curl_proxy -sfLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

install_nvim()
{
    local nvim_url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz"
    local old_dir=$PWD
    cd "$ToolsDir"
    $curl_proxy -fL "$nvim_url" | tar -xzf -
    ln -sf $PWD/nvim-linux64/bin/nvim ${BinaryDir}/nvim
    cd ${old_dir}
}

plug_install()
{
    $curl_proxy -sL install-node.now.sh/lts | sed '/confirm /d'  | bash
    export PATH=${BinaryDir}:$PATH
    which nvim
    echo "-----------------------------------------------------------"
    nvim +'PlugInstall --sync' +'PlugUpdate' +qa!
    nvim +'PlugInstall --sync' +'PlugUpdate' +qa!
}

cmake_install()
{
    local old_dir=$PWD
    cd "$ToolsDir"
    git clone https://github.com/Kitware/CMake.git
    cd CMake && git checkout `git describe --abbrev=0 --tags`
    ./bootstrap && make -j`nproc` && ${SUDO} make install
    cd ${old_dir}
}

ccls_install()
{
    ${InstallCommand} clang-8 clang-tools-8 libclang-8-dev
    ${SUDO} ln -sf /usr/bin/clang-8 /usr/bin/clang
    ${SUDO} ln -sf /usr/bin/clang++-8 /usr/bin/clang++

    local old_dir=$PWD
    cd "$ToolsDir"

    git clone --recursive https://github.com/MaskRay/ccls
    cd ccls && git checkout `git describe --abbrev=0 --tags`
    cmake  -H. -BRelease -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_RTTI=ON
    cmake --build Release -j`nproc`
    ln -sf `pwd`/Release/ccls ${BinaryDir}/ccls
    cd ${old_dir}
}
install_fzf_z()
{
    local old_dir=$PWD
    cd "$ToolsDir"

    git clone --depth 1 https://github.com/skywind3000/z.lua.git ~/.z.lua

    if ls $HOME/.fzf/bin/fzf 1> /dev/null 2>&1; then
        echo "fzf exist"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        yes | ~/.fzf/install
    fi 
    cd ${old_dir}
}

install_fd_rg()
{
    local old_dir=$PWD
    cd "$ToolsDir"

    fd_url=https://github.com/sharkdp/fd/releases/download/v8.2.1/fd-v8.2.1-x86_64-unknown-linux-musl.tar.gz
    rg_url=https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-x86_64-unknown-linux-musl.tar.gz

    $curl_proxy -fL $fd_url | tar -xzf -
    $curl_proxy -fL $rg_url | tar -xzf -
    mv `pwd`/fd-v8.2.1-x86_64-unknown-linux-musl/fd ${BinaryDir}/fd
    mv `pwd`/ripgrep-12.1.1-x86_64-unknown-linux-musl/rg ${BinaryDir}/rg

    cd ${old_dir}
}

setting_git_config()
{
    git config --global alias.tree "log --graph --all --relative-date --abbrev-commit --format=\"%x09 %h %Cgreen%cd%Creset [%Cblue%cn%Creset] %C(auto)%d%Creset %s\""
    git config --global http.proxy 'socks5://192.168.2.105:1080'
}

update_bashrc_env()
{

    echo "export PATH=\$PATH:$BasePath/bashrc" >> $HOME/.bashrc
}

copy_confif_files()
{
    $BasePath/.inputrc $HOME
    $BasePath/.tmux_conf $HOME
    ln -sf $BasePath/nvim/init.vim $HOME/.config/nvim/init.vim
    ln -sf $BasePath/nvim/coc-settings.json  $HOME/.config/nvim/coc-settings.json
}

update_ubuntu_source_list()
{
    echo "update source list"
    mv /etc/apt/sources.list /etc/apt/sourses.list.backup

    tee /etc/apt/sources.list <<-'EOF'
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
}
main()
{
    [ $# -ne 0 ] && update_ubuntu_source_list
    create_tools_dir
    create_binary_dir
    update_sudo
    setting_git_config
    update_install_command
    ubuntu_install_prepare_software
    install_vim_plug
    install_nvim
    copy_confif_files
    plug_install
    cmake_install
    ccls_install
    install_fzf_z
    install_fd_rg
    update_bashrc_env
}

main "$@"

