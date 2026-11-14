cd /app/dist_injected
f=
echo TESTFILE=
sed -i 's/Stoat/SpeekFlow/g' $f && echo SED_OK || echo SED_FAIL
