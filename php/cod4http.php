<?php
    require_once( 'guard.php' );
    $rawdata = file_get_contents( 'php://input' );
    $values = json_decode( $rawdata, TRUE );

    if( !isset( $values[ 'query' ] ) )
    {
        $response = array( 'status' => 'invalid_inputparamters' );
        $json = json_encode( $response );
        echo $json;
        return;
    }

    $conn = new mysqli( $values[ 'host' ], $values[ 'user' ], $values[ 'password' ], $values[ 'database' ] );
    if( $conn->connect_error )
    {
        $response = array( 'status' => 'connection_failed' );
        $json = json_encode( $response );
        echo $json;
        return;
    }

    $result = $conn->query( $values[ 'query' ] );
  
    if( is_object( $result ) )
    {
        if( $result->num_rows > 0 )
        {
            $rows = array();
            $i = 0;
            while( $row = $result->fetch_assoc() )
            {
                $rows[ ''. $i ] = $row;
                $i++;
            }
            $rows[ 'status' ] = 'okay';
            $rows[ 'num' ] = '' . $i;

            $json = json_encode( $rows );
            echo $json;
        }
        else
        {
            $response = array( 'status' => 'no_results' );
            $json = json_encode( $response );
            echo $json;
        }
    }
    else
    {
        if( $result )
        {
            $response = array( 'status' => 'okay' );
            $json = json_encode( $response );
            echo $json;
        }
        else
        {
            $response = array( 'status' => 'failure' );
            $json = json_encode( $response );
            echo $json;
        }
    }

    $conn->close();