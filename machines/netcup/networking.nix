{
  networking = {
    useDHCP = false;
    usePredictableInterfaceNames = false;
    nameservers = [ "1.1.1.1" "9.9.9.9" ];
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "89.58.54.56";
        prefixLength = 22;
      }];

      ipv6.addresses = [{
        address = "2a03:4000:69:c35::";
        prefixLength = 64;
      }];
    };
    defaultGateway = "89.58.52.1";
  };
}
