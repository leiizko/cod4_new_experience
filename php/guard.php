<?php
 
    $ip = $_SERVER['REMOTE_ADDR'];
 
    if($ip !== "176.31.25.80" && $ip !== "164.132.119.140" && $ip !== "127.0.0.1")
    {
        if($ip !== "2001:41d0:a:37ad::1ce0" && $ip !== "2001:41d0:a:37ad::c0d4" && $ip !== "::1")
        {
            die( json_encode( array( 'status' => 'illegal_access' ) ) );
        }
    }