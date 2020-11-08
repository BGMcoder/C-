<%@ Page Language="C#" Debug="true" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Drawing" %>
<%@ Import Namespace="System.Drawing.Imaging" %>
<%@ Import Namespace="System.Drawing.Drawing2D" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="orsus" %>
<%@ Import Namespace="Microsoft.VisualBasic" %>
<%

		/*  Tuxtax.aspx - The C# Hit Counter
	 *	Sunday, November 08, 2020
	 *	Just add this file into your website (doesn't need to be compiled in this format, but it would probably run faster if you added it into
	 *	your compiled project.  Just make the aspx page to which the code belongs a blank page.)
	 *	Requirements: an image sprite of the digits, 0 through 9 all of even width.
	 *	A folder named /Counters containing a text file with the counter's name  (such as "thiscounter.txt")
	 *	The site's app pool identity needs to have permissions to modify the contents of this /Counters folder.		
	 *  Original idea in old vb.net from here: https://www.developerfusion.com/code/3734/aspnet-graphical-page-hit-counter/
	 */
	//useage: <img src="/tuxtax.aspx?name=[countername]&src=[digitsimage.gif]&digits=[numberdigits]">
	//example: <img src="/tuxtaxy.aspx?name=myCounter&src=/images/digits.gif&digits=5" alt="hit-counter" class="counter"/>

	//We are fetching the counter values from the src supplied in the image tag element
	string counterid = Request.QueryString["id"];
	string digitsfile = Request.QueryString["src"];

	//Now build the path the text file from the counterid
	string countertext = "~/counters/" + counterid + ".txt";


	//Get the current counter value - there won't be a value unless the page has been processed once already; 
	//this is to prevent multiple hits on successive reloads
	int countervalue = Convert.ToInt32(Application.Get("Counter_" + counterid));

	//Check whether our asp session cookie Is in place; if it hasn't expired, don't count hits
	if (Session["CounterTemp_" + counterid] == null) {
		//If the counter text file exists, then load the saved value
		//Always loading it from the file instead of using application variables allows us to be able to manually edit that file whist the app Is running
		//To stop it from being able to be manually edited, just uncomment the following if statement
		if (countervalue == 0) {
			if (File.Exists(Server.MapPath(countertext))) {
				StreamReader thisreader = File.OpenText(Server.MapPath(countertext));
				countervalue = Convert.ToInt32(thisreader.ReadLine().ToString());
				thisreader.Close();
			}
		}

		//Now increment the counter value
		countervalue += 1;

		//Save the counter to an application variable (The locks are there to make sure nobody else changes it at the same time
		Application.Lock();
		Application.Set("Counter_" + counterid, countervalue.ToString());
		Application.UnLock();

		//Save the counter value to the text file
		FileStream filereader = new FileStream(Server.MapPath(countertext), FileMode.Create, FileAccess.Write);
		StreamWriter streamwriter = new StreamWriter(filereader);
		streamwriter.WriteLine(Convert.ToString(countervalue));
		streamwriter.Close();
		filereader.Close();

		//Set a session variable so this counter doesn't fire again in the current session
		Session.Add(("CounterTemp_" + counterid), "true");
	}

	//CREATE OUTPUT GRAPHIC FOR THE COUNTER*******************************************************

	//Load the digits graphic (must be in 0-9 format in graphic with all the digits of set width)
	System.Drawing.Image digitpix = System.Drawing.Image.FromFile(Server.MapPath(digitsfile));

	//Get the digit dynamics from the graphic
	int digitwidth = digitpix.Width / 10;   //the width of each little number - should be 15px for my digits.gif
	int digitheight = digitpix.Height;      //should be 20px for my digits.gif;

	//Get the number of digits to display in the output graphic
	//If the countervalue is 16 then "16".ToString("D5") converts it to "00016".  
	//ToCharArray() turns that into an array of characters ['0', '0', '0', '1', '6']. 
	//We loop through that list and convert the char back to int and we get 0, 0, 0, 1 and 6.
	//Thanks to @Aidy in the C# Discord for help on this

	int numdigits = Convert.ToInt32(Request.QueryString["digits"]);
	var digits = countervalue.ToString("D" + numdigits.ToString()).ToCharArray();

	//Create an output object
	Bitmap imageoutput = new Bitmap(digitwidth * digits.Length, digitheight, PixelFormat.Format24bppRgb);  //should be 5*15 = 75 for digits.gif
	Graphics graphic = Graphics.FromImage(imageoutput);  //here is our black box

	//digits.gif is 150 x 20px; 
	//So, if our countervalue = 16, and numdigits = 5, we want to display 00016.

	for(int j = 0; j < digits.Length; j++) {
		//We loop through that digits and convert the char back to int and we get 0, 0, 0, 1 and 6.
		int thisdigitX = int.Parse(digits[j].ToString());

		//add the digit to the output graphic 
		graphic.DrawImage(digitpix, new Rectangle(j * digitwidth, 0, digitwidth, digitheight), new Rectangle(thisdigitX * digitwidth, 0, digitwidth, digitheight), GraphicsUnit.Pixel);
	}

	Response.Clear();
	Response.ContentType = "image/jpeg";
	imageoutput.Save(Response.OutputStream, ImageFormat.Jpeg);
	Response.End();

	//Set the content type and return the output image
	graphic.Dispose();
	imageoutput.Dispose();

%>
