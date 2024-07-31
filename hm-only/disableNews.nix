disableHomeManagerNews = {
  # disabledModules = [ "misc/news.nix" ];
  config = {
    news.display = "silent";
    news.json = lib.mkForce { };
    news.entries = lib.mkForce [ ];
  };
};
