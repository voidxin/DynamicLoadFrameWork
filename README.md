 在真机上运行的时候frameWork的签名必须和主工程的签名一致，由于iOS10之后系统不允许从documents读取文件，所以iOS10之后动态加载frameWork的通道被堵死。iOS10之前亲测是可用的
   详情可见这篇博客:http://nixwang.com/2015/11/09/ios-dynamic-update/
