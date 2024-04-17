nfs1 ansible_host=${nfs1_ip}
db1 ansible_host=${db1_ip}
lb1 ansible_host=${lb1_ip}
appgogs_1 ansible_host=${appgogs_1_ip}
appgogs_2 ansible_host=${appgogs_2_ip}

[nfs]
nfs1

[db]
db1

[lb]
lb1

[app]
appgogs_1
appgogs_2