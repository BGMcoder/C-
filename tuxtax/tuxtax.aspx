<%@ Page Language="C#" Debug="true" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Drawing" %>
<%@ Import Namespace="System.Drawing.Imaging" %>
<%@ Import Namespace="System.Drawing.Drawing2D" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="orsus" %>
<%



	//useage = <img src="/tuxtax.aspx?src=digits.gif&digits=5&id=countername">

	//We are fetching the counter values from the src supplied in the image tag element
	string counterid = Request.QueryString["name"];

	string digitsfile = "~/images/" + Request.QueryString["src"];
	//Now build the path the text file from the counterid
	string countertext = "~/counters/" + counterid + ".txt";


	//Get the current counter value - there won't be a value unless the page has been processed once already; this is to prevent multiple hits on successive reloads
	int countervalue = Convert.ToInt32(Application.Get("Counter_" + counterid));

	//Check whether our cookie Is in place

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

	//Load the digits graphic (must be in 0-9 format in graphic with all the digits of set width
	System.Drawing.Image digitpix = System.Drawing.Image.FromFile(Server.MapPath(digitsfile));

	//Get the digit dynamics from the graphic
	int digitwidth = digitpix.Width / 10;	//the width of each little number - should be 15px
	int digitheight = digitpix.Height;		//should be 20px;

	//Get the number of digits to display in the output graphic
	int numdigits = Convert.ToInt32(Request.QueryString["digits"]);

	//Create an output object
	Bitmap imageoutput = new Bitmap(digitwidth * numdigits, digitheight, PixelFormat.Format24bppRgb);  //should be 5*15 = 75
	Graphics graphic = Graphics.FromImage(imageoutput);  //here is our black box

	//digits.gif is 150 x 20px  - for 5 digits, the output is 70 x 20 but it should be 80 because the 4 digits should have a 0 in front of them
	for(int j = 0; j <= (numdigits - 1); j++) {
		//extract digit from the value
		//double thisdigit = Math.Truncate((double)(countervalue / (10 ^ (numdigits - j - 1)))) - Math.Truncate(((double)(countervalue / (10 ^ (numdigits - j))) * 10));
		int thisdigit = (countervalue / (10 ^ (numdigits - j - 1))) - ((countervalue / (10 ^ (numdigits - j))) * 10);
		//int thisdigit = (int)(Math.Truncate((double)countervalue / Math.Pow(10, (double)(numdigits - j - 1))) - Math.Truncate((double)countervalue / Math.Pow(10, (double)(numdigits - j))) * 10);


		//add the digit to the output graphic 
		graphic.DrawImage(digitpix, new Rectangle(j * digitwidth, 0, digitwidth, digitheight), new Rectangle(thisdigit * digitwidth, 0, digitwidth, digitheight), GraphicsUnit.Pixel);
	}

	Response.Clear();
	Response.ContentType = "image/jpeg";
	imageoutput.Save(Response.OutputStream, ImageFormat.Jpeg);
	Response.End();

	//Set the content type and return the output image
	graphic.Dispose();
	imageoutput.Dispose();

%>
