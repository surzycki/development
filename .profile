# This PS1 snippet was adopted from code for MAC/BSD I saw from: http://allancraig.net/index.php?option=com_content&view=article&id=108:ps1-export-command-for-git&catid=45:general&Itemid=96
# I tweaked it to work on UBUNTU 11.04 & 11.10 plus made it mo' better

export PS1="(*) \[\033[0;37m\]"\\u:"\[\033[0m\]"'$(git branch &>/dev/null;\
if [ $? -eq 0 ]; then \
  echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
  if [ "$?" -eq "0" ]; then \
    # @4 - Clean repository - nothing to commit
    echo "'"\[\033[0;32m\]"'"$(__git_ps1 " (%s)"); \
  else \
    # @5 - Changes to working tree
    echo "'"\[\033[0;31m\]"'"$(__git_ps1 " (%s)"); \
  fi) '"\[\033[0;33m\]"\\w"\[\033[0m\]"'\$ "; \
else \
  # @2 - Prompt when not in GIT repo
  echo " '"\[\033[0;33m\]"\\w"\[\033[0m\]"'\$ "; \
fi)'

alias dc="docker-compose"

alias k="kubectl"

# Editor
export EDITOR=vim
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/config.eks
