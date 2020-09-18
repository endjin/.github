function New-RsaSha256Signature
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $pem,

        [Parameter()]
        [string] $data
    )

    $here = Split-Path -Parent $PSCommandPath
    Use-Assembly -Path ([IO.Path]::Combine($here, '..', 'lib', 'BouncyCastle.Crypto.dll')) | Out-Null

	# Prepare private key
    Invoke-WithUsingObject ($sr = New-Object System.IO.StringReader $pem) {
        Invoke-WithUsingObject ($pr = New-Object Org.BouncyCastle.OpenSsl.PemReader $sr) {
            $key = ([Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair] ($pr.ReadObject())).Private
        }
    } 

	$dataBytes = [System.Text.UTF8Encoding]::UTF8.GetBytes($data)

    $normalSig = [Org.BouncyCastle.Security.SignerUtilities]::GetSigner("SHA256WithRSA")
    $normalSig.Init($true, $key)
    $normalSig.BlockUpdate($dataBytes, 0, $dataBytes.Length)
    [byte[]] $normalResult = $normalSig.GenerateSignature()

	# return the base64 encoded string
	return [Convert]::ToBase64String($normalResult)

}