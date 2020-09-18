function New-GitHubJWT
{
    [CmdletBinding()]
    param (   
        [Parameter(Mandatory = $True)]
        [string] $Issuer,
    
        [Parameter(Mandatory = $True)]
        [string] $PrivateKeyPem,

        [int] $ValidforSeconds = 300
    )

    $now = (Get-Date).ToUniversalTime()
    $iat = [int][double]::parse((Get-Date -Date $now -UFormat %s))
    $exp = [int][double]::parse((Get-Date -Date ($now.addseconds($ValidforSeconds)) -UFormat %s)) # Grab Unix Epoch Timestamp and add desired expiration.

    [hashtable]$header = @{alg = 'RS256'}
    [hashtable]$payload = @{iss = $Issuer; iat = $iat; exp = $exp}

    $headerjson = $header | ConvertTo-Json -Compress
    $payloadjson = $payload | ConvertTo-Json -Compress
    
    $headerjsonbase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($headerjson)).Split('=')[0].Replace('+', '-').Replace('/', '_')
    $payloadjsonbase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payloadjson)).Split('=')[0].Replace('+', '-').Replace('/', '_')

    $unsignedJwt = $headerjsonbase64 + "." + $payloadjsonbase64
    $signature = New-RsaSha256Signature -data $unsignedJwt -pem $PrivateKeyPem
    $jwtSig = $signature.Split('=')[0].Replace('+', '-').Replace('/', '_')

    $token = "$headerjsonbase64.$payloadjsonbase64.$jwtSig"
    $token
}