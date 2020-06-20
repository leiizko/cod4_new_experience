<?php
    require_once( 'guard.php' );
    $rawdata = file_get_contents( 'php://input' );
//file_put_contents( 'input.txt', $rawdata );
    $values = json_decode( $rawdata, TRUE );

    /*if( !isset( $values[ 'content' ] ) && !isset( $values[ 'embed' ] ) )
    {
        $response = array( 'status' => 'invalid_inputparamters' );
        $json = json_encode( $response );
file_put_contents( 'error1.txt', $json );
        echo $json;
        return;
    }*/

    $url = "DISCORD API LINK";
	
	$ch = curl_init( $url );
 
	curl_setopt( $ch, CURLOPT_POST, 1 );
 
	curl_setopt( $ch, CURLOPT_POSTFIELDS, $rawdata );

        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
 
	curl_setopt( $ch, CURLOPT_HTTPHEADER, array( 'Content-Type: application/json' ) ); 
 
	$result = curl_exec($ch);

//file_put_contents( 'result.txt', $result );
	
	$response = array( 'status' => (string)curl_errno( $ch ) );
	$json = json_encode( $response );
//file_put_contents( 'error.txt', $json );
    echo $json;
	
	curl_close( $ch );
?>
