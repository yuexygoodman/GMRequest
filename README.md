# GMRequest
A library for simplifying network program.

这个库是对AFNetwork的进一步封装，根据一些网络编程习惯提供了一套新的API，同时提供了以同步的方式发起请求
下面是一些简单的例子：

    [[GMRequest request] getWithUrl:@"your url address" finish:^(id resData, NSError *error) {
        NSLog(@"%@",resData);
    }];
    
    [[GMRequest request] postWithUrl:@"your url address" parameters:nil finish:^(id resData, NSError *error) {
        NSLog(@"%@",resData);
    }];
    
    [[GMRequest request] uploadWithUrl:@"your url address" headers:nil parameters:nil files:nil progress:nil finish:^(id resData, NSError *error) {
        NSLog(@"%@",error);
    }];
    
    [[GMRequest request] downloadWithUrl:@"your url address" parameters:nil finish:^(id resData, NSError *error) {
        NSLog(@"%@",resData);
    }];
    
    //同步请求
    GMRequest *newRequest=[GMRequest request];
    newRequest.synchronous=YES;
    [newRequest getWithUrl:@"your url address" finish:^(id resData, NSError *error) {
        NSLog(@"%@",resData);
    }];
