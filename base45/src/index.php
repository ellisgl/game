<?php

include __DIR__ . '/../vendor/autoload.php';

use chillerlan\QRCode\Output\QROutputInterface;
use Mhauri\Base45;
use chillerlan\QRCode\QRCode;
use chillerlan\QRCode\QROptions;
use chillerlan\QRCode\Common\EccLevel;

$qrOptions                  = new QROptions(
    [
        'outputType'      => QROutputInterface::GDIMAGE_PNG, // Specify the output type as GD image
        'quality'         => 100, // Set quality to maximum
        'version'         => 40,
        'eccLevel'        => EccLevel::Q,
        'imageBase64'     => false, // Set to false to get GD image resource instead of base64 encoded string
        'returnResource'  => true, // Ensure we get the GD image resource
    ]
);

$base45 = new Base45();
$contents = file_get_contents(__DIR__ . '/../../build/dist/Game.tar.bz2');
// BZ2  = Bzip2 compressed file
// NES  = File format for NES ROM
// GAME = File name
$encoded = '%%:BZ2:NES:GAME:%%' . $base45->encode($contents);


$qrCode = new QRCode($qrOptions);
$rendered = $qrCode->render($encoded);

// GD image resource is returned, save as PNG.
imagepng($rendered, __DIR__ . '/../../build/dist/Game.png');
