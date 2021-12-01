Param(
    [string]$commit_msg = ("Update")
)

Set-Location blog
hugo
Set-Location ..
git add .
git commit -m $commit_msg
git push origin master
