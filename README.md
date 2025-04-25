# flake 脚手架

# 使用

一般只需要
```
nix run github:Rikki-Zero/flake-init

# 或者下面的写法也可以
nix run github:Rikki-Zero/flake-init#flake-init
```

如果脚本版本更新了，可以使用下面的写法来刷新本地缓存

```
nix run --refresh github:Rikki-Zero/flake-init
```
