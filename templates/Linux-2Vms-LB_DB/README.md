###Create 2 FrontEnd Vms with 1 DB VM at Backend###

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FHatemAlSum%2Fazure-picks%2Fmaster%2Ftemplates%2FLinux-2Vms-LB_DB%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FHatemAlSum%2Fazure-picks%2Fmaster%2Ftemplates%2FLinux-2Vms-LB_DB%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

Description of Template
=======================
This template allows you to deploys three Linux VMs , Two VMs as WebFrontend Node with Load Balancer and 1 VM as Database Node ,
also Nat rules are configure to access the nodes using ssh and also nat rule for phpmyadmin for db node 
all port are secured with Network Security Group

How to connect to your VM
=========================
Use below script to connect to deployed linux vms throw nat rules

    hostName=<DNS NAME>
    adminuser=<adminUsername>

    #First VM : WebNode1
    ssh $hostname -l $adminuser -p 65122
    #Second VM: WebNode2
    ssh $hostname -l $adminuser -p 65222
    #Third VM :  DB Node
    ssh $hostname -l $adminuser -p 65322
