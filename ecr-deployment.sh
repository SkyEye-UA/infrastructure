aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 213937518703.dkr.ecr.eu-central-1.amazonaws.com
docker tag d8a5b7adb54e 213937518703.dkr.ecr.eu-central-1.amazonaws.com/sky-eye-ecr-repository:sky-eye-userservice-no-cache-1
docker push 213937518703.dkr.ecr.eu-central-1.amazonaws.com/sky-eye-ecr-repository:sky-eye-userservice-no-cache-1