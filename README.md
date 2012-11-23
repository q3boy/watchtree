# Watch tree
![travis build info](https://api.travis-ci.org/q3boy/watchtree.png)

a library for watching FS trees

## new WatchTree(dir1 [, dir2...] [,options])

* dir1, dir2...: 监听目录列表
* options: 配置
	* emitDelay: 事件触发延时(ms), 默认50, 防止长时间修改文件引起的频繁事件触发
	* filter: 文件名过滤规则, 仅对file生效. 默认为 /\.(js|coffee|css|styl|stylus|md|yaml|jade|json|jpg|jpeg|png|gif|swf|ico|ini|html|htm|xml|txt)$/ 

## WatchTree.stop()
停止所有监听对象

## Events

### mkdir
新建目录 `wt.on('mkdir', function(file){console.log('mkdir:', file)});`

### rmdir
删除目录 `wt.on('rmdir', function(file){console.log('rmdir:', file)});`

### created
新建文件 `wt.on('created', function(file){console.log('created:', file)});`

### removed
删除文件 `wt.on('removed', function(file){console.log('removed:', file)});`

### changed
文件内容修改 `wt.on('changed', function(file){console.log('changed:', file)});`

### all
包括上述所有事件 `wt.on('all', function(event, file){console.log(event, file)});`


## 示例

```javascript
var watchTree = require('watachtree');

var wt = watchTree('./dir1', './dir2', /\.js$/);

wt.on('all', function(evt. file){
	console.log(event, file);
});

setTimeout (fs.mkdir dir+'/dir3/', '0755'), 0
setTimeout (fs.mkdir dir+'/dir3/dir4/', '0755'), 50
setTimeout (fs.mkdir dir+'/dir3/dir4/dir5', '0755'), 100
setTimeout (fs.writeFile dir+'/dir3/dir4/dir5/file4.js', 'somedata1'), 150
setTimeout (fs.writeFile dir+'/dir3/dir4/dir5/file5.js', 'somedata2'), 200
```
