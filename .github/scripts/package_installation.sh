TARGET_ORG=$1

# DealHub package installation
if [ -n "$TARGET_ORG" ]; then
    sf package install --package 04t6g000008flShAAI --target-org $TARGET_ORG --wait 3
else
    sf package install --package 04t6g000008flShAAI --wait 3
fi

# Ironclad package installation
if [ -n "$TARGET_ORG" ]; then
    sf package install --package 04t3u0000038RrZAAU --target-org $TARGET_ORG --wait 3 --no-prompt
else
    sf package install --package 04t3u0000038RrZAAU --wait 3 --no-prompt
fi