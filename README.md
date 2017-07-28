makes github search grep and pipeable

# Setup
 - create a [application token](https://github.com/settings/applications) with read access
 - clone repo
 - set env variable GITHUB_AUTH_TOKEN
```
~/github-grep/$ bundle install
```
Add ~/github-grep/bin to your path

```

# search code:
github-grep 'user:grosser unicorn' | grep 'narrow-it-down' | grep -v 'something good'

# search issues and PR comments:
github-grep 'repo:kubernetes/kubernetes network error' --issues | grep 'narrow-it-down' | grep -v 'something good'
```
