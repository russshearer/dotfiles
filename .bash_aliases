# ~/.bash_aliases — Russ's homelab aliases
# Sourced from .bashrc

# ----------------------------------------------------------
# General
# ----------------------------------------------------------
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'
alias reload='source ~/.bashrc && echo "bashrc reloaded"'
alias dotfiles='cd ~/.dotfiles'

# ----------------------------------------------------------
# Kubernetes
# ----------------------------------------------------------
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kgaa='kubectl get all -A'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdn='kubectl describe node'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kctx='kubectl config get-contexts'
alias kns='kubectl config set-context --current --namespace'
alias kwatch='watch -n2 kubectl get pods -A'

# kubectl autocomplete for aliases
complete -o default -F __start_kubectl k 2>/dev/null

# ----------------------------------------------------------
# Terraform
# ----------------------------------------------------------
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfaa='terraform apply -auto-approve'
alias tfd='terraform destroy'
alias tfs='terraform state'
alias tfo='terraform output'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'

# ----------------------------------------------------------
# Git
# ----------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate -20'

# ----------------------------------------------------------
# System
# ----------------------------------------------------------
alias sctl='sudo systemctl'
alias jctl='sudo journalctl'
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'

# ----------------------------------------------------------
# Proxmox (for when SSH'd into a PVE host)
# ----------------------------------------------------------
alias qml='qm list'
alias qms='qm status'
alias qmstart='qm start'
alias qmstop='qm stop'
alias qmsnap='qm snapshot'
