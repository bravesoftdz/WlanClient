Unit WlanHostedNetwork;

Interface

Uses
  WlanAPI, WlanAPIClient;

Type
  TWlanHostedNetwork = Class
    Private
      FClient : TWlanAPIClient;
      FSSID : WideString;
      FPassword : WideString;
      FPersistent : Boolean;
      FCipherAlgo : Cardinal;
      FAuthAlgo : Cardinal;
      FMaxPeers : Cardinal;
      FEnabled : Boolean;
      FActive : Boolean;
    Public
      Constructor Create(AClient:TWlanAPIClient); Reintroduce;

      Function Refresh:Boolean;
      Function SetPassword(APassword:WideString; APersistent:Boolean):Boolean;
      Function SetConnectionSettings(ASSID:WIdeString; AMaxPeers:Cardinal = 100):Boolean;
      Function SetSecuritySettings(AAuthAlgo:Cardinal; ACipherAlgo:Cardinal):Boolean;
      Function Enable:Boolean;
      Function Disable:Boolean;
      Function Start:Boolean;
      Function Stop:Boolean;

      Property SSID : WideString Read FSSID;
      Property Password : WideString Read FPassword;
      Property Persistent : Boolean Read FPersistent;
      Property CipherAlog : Cardinal Read FCipherAlgo;
      Property AuthAlgo : Cardinal Read FAuthAlgo;
      Property MaxPeers : Cardinal Read FMaxPeers;
      Property Enabled : Boolean Read FEnabled;
      Property Active : Boolean Read FActive;
    end;


Implementation

Uses
  SysUtils;


Constructor TWlanHostedNetwork.Create(AClient:TWlanAPIClient);
begin
Inherited Create;
FClient := AClient;
If Not FClient._WlanHostedNetworkInitSettings Then
  Raise Exception.Create('Unable to initialize the HN');

If Not Refresh Then
  Raise Exception.Create('Unable to retrieve HN properties');
end;

Function TWlanHostedNetwork.Refresh:Boolean;
Var
  I : Integer;
  dataSize : Cardinal;
  valueType : WLAN_OPCODE_VALUE_TYPE;
  cs : PWLAN_HOSTED_NETWORK_CONNECTION_SETTINGS;
  ss : PWLAN_HOSTED_NETWORK_SECURITY_SETTINGS;
  st : PWLAN_HOSTED_NETWORK_STATUS;
  key : PAnsiChar;
  keySize : Cardinal;
  isPassphrase : LongBool;
  isPersistent : LongBool;
  e : PLongBool;
begin
Result := FClient._WlanHostedNetworkQueryProperty(wlan_hosted_network_opcode_connection_settings, dataSize, Pointer(cs), valueType);
If Not Result Then
  Exit;

FMaxPeers := cs.MaxPeers;
SetLength(FSSID, cs.SSID.uSSIDLength);
For I := 1 To cs.SSID.uSSIDLength Do
  FSSID[I] := WideChar(cs.SSID.ucSSID[I - 1]);

WlanFreeMemory(cs);
Result := FClient._WlanHostedNetworkQueryProperty(wlan_hosted_network_opcode_security_settings, dataSize, Pointer(ss), valueType);
If Not Result Then
  Exit;

FAuthAlgo := ss.AuthAlgo;
FCipherAlgo := ss.CipherAlgo;
WlanFreeMemory(ss);
Result := FClient._WlanHostedNetworkQuerySecondaryKey(keySize, key, isPassPhrase, isPersistent);
If Not Result Then
  Exit;

If IsPassPhrase Then
  Dec(keySize);

SetLength(FPassword, keySize);
For I := 1 To keySize Do
  FPassword[I] := WideChar(key[I - 1]);

FPersistent := IsPersistent;
WlanFreeMemory(key);
Result := FClient._WlanHostedNetworkQueryProperty(wlan_hosted_network_opcode_enable, dataSize, Pointer(e), valueType);
If Not Result Then
  Exit;

FEnabled := e^;
WlanFreeMemory(e);
Result := FClient._WlanHostedNetworkQueryStatus(st);
If Not Result Then
  Exit;

Case st.HostedNetworkState Of
  wlan_hosted_network_idle : FActive := False;
  wlan_hosted_network_active : FActive := True;
  end;

WlanFreeMemory(st);
end;



Function TWlanHostedNetwork.SetPassword(APassword:WideString; APersistent:Boolean):Boolean;
Var
  I : Integer;
  key : PAnsiChar;
begin
If Length(APassword) > 0 Then
  begin
  key := WLanAllocateMemory(Length(APassword) + 1);
  Result := Assigned(key);
  If Result Then
    begin
    FillChar(key^, Length(APassword) + 1, 0);
    For I := 1 To Length(APassword) Do
      key[I - 1] := AnsiChar(APassword[I]);

    Result := FClient._WlanHostedNetworkSetSecondaryKey(Length(APassword) + 1, key, True, APersistent);
    WlanFreeMemory(key);
    end;
  end
Else Result := FClient._WlanHostedNetworkSetSecondaryKey(0, Nil, True, APersistent);
end;

Function TWlanHostedNetwork.SetConnectionSettings(ASSID:WIdeString; AMaxPeers:Cardinal = 100):Boolean;
Var
  I : Integer;
  cs : WLAN_HOSTED_NETWORK_CONNECTION_SETTINGS;
begin
FillChar(cs, SizeOf(cs), 0);
cs.MaxPeers := AMaxPeers;
cs.SSID.uSSIDLength := Length(ASSID);
For I := 1 To Length(ASSID) Do
  cs.SSID.ucSSID[I - 1] := Byte(ASSID[I]);

Result := FClient._WlanHostedNetworkSetProperty(wlan_hosted_network_opcode_connection_settings, SizeOf(cs), @cs);
end;

Function TWlanHostedNetwork.SetSecuritySettings(AAuthAlgo:Cardinal; ACipherAlgo:Cardinal):Boolean;
Var
  ss : WLAN_HOSTED_NETWORK_SECURITY_SETTINGS;
begin
FillChar(ss, SizeOf(ss), 0);
ss.AuthAlgo := AAuthAlgo;
ss.CipherAlgo := ACipherAlgo;
Result := FClient._WlanHostedNetworkSetProperty(wlan_hosted_network_opcode_security_settings, SizeOf(ss), @ss);
end;

Function TWlanHostedNetwork.Enable:Boolean;
Var
  e : LongBool;
begin
e := True;
Result := FClient._WlanHostedNetworkSetProperty(wlan_hosted_network_opcode_enable, SizeOf(e), @e);
end;

Function TWlanHostedNetwork.Disable:Boolean;
Var
  e : LongBool;
begin
e := False;
Result := FClient._WlanHostedNetworkSetProperty(wlan_hosted_network_opcode_enable, SizeOf(e), @e);
end;

Function TWlanHostedNetwork.Start:Boolean;
begin
Result := FClient._WlanHostedNetworkStartUsing;
end;


Function TWlanHostedNetwork.Stop:Boolean;
begin
Result := FClient._WlanHostedNetworkStopUsing;
end;


End.