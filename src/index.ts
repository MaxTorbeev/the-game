import dotenv from "dotenv";
import express from 'express'
import path from "path";

const app = express();

// initialize configuration
dotenv.config();

const port = process.env.SERVER_PORT;

// Configure Express to use EJS some comment
app.set( "views", path.join( __dirname, "views" ) );
app.set( "view engine", "ejs" );

// define a route handler for the default home page
app.get( "/", ( req, res ) => {
    // render the index template
    res.render( "index" );
} );

app.listen( port, () => {
    // tslint:disable-next-line:no-console
    console.log( `server started at http://localhost:${ port }` );
} );
