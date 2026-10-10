# Portable aliases (no secrets, no machine-specific paths).

alias v=nvim
# alias code=nvim        # uncomment once fully off VS Code
alias dk='docker'
alias pat='batcat'
alias golli='cd ~/github/olli'

# reload the status bar (eww on this machine; was polybar elsewhere)
alias rlbr='~/.config/eww/launch-eww.sh &'

# kubectl context switches (contexts themselves are cluster-generic ARNs; adjust as needed)
alias kswus='kubectl config use-context arn:aws:eks:us-east-1:905418372464:cluster/buddyos'
alias kswap='kubectl config use-context arn:aws:eks:ap-southeast-1:905418372464:cluster/eks-primary-prod-01'
