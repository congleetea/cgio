0 install: sudo apt-get install subversion
1 从服务器上down代码: svn co URLPath

2 往里面添加东西: svn add FileOrDir, 可以先复制到目录里面.
  删除文件或者目录: svn delete FileOrDir
3 提交到服务器: svn commit -m "...." FileOrDir , 注意要在你更改的目录下面,不要在上层目录.
4 从服务器上更新代码: svn update 
5 查看文件或目录的状态(?,M,C,A,K): svn state FileOrDir
