<%@ Page Language="C#" %>

<script runat="server">
// source: https://github.com/PilotGaeaRD/WebProxy/blob/master/oview.aspx
    private void Page_Load(object sender, EventArgs e)
    {
        string url = HttpUtility.UrlDecode(Page.ClientQueryString);

        if (!ValidateWhiteList(url))
        {
            Response.StatusCode = 403;
            Response.StatusDescription = "Forbidden:Target url not be allowed by administrator.";
            return;
        }
        // check is post
        bool post = Request.InputStream.Length > 0;
        byte[] postBuffer = null;
        if (post) // get post data
        {
            postBuffer = new byte[Request.InputStream.Length];
            Request.InputStream.Read(postBuffer, 0, postBuffer.Length);
        }

        System.Net.HttpWebRequest req = System.Net.WebRequest.Create(url) as System.Net.HttpWebRequest;
        req.Method = post ? "POST" : "GET";
        if (post)// for pilotgaea docmd only
        {
            req.ContentLength = postBuffer.Length;
            req.ContentType = "application/json";
        }
        req.UserAgent = "PilotGaea Proxy Server";

        // copy cookie
        NameValueCollection headers = Request.Headers;
        for (int i = 0; i < headers.Count; i++)
        {
            if (headers.GetKey(i) == "Cookie")
            {
                req.Headers.Set("Cookie", headers.Get(i));
                break;
            }
        }

        byte[] retBuffer = null;
        try
        {
            if (post)
            {
                //¤W¶Ç
                System.IO.Stream stream_req = req.GetRequestStream();
                stream_req.Write(postBuffer, 0, postBuffer.Length);
                stream_req.Flush();
                stream_req.Close();
            }

            System.Net.HttpWebResponse res = req.GetResponse() as System.Net.HttpWebResponse;
            System.IO.Stream stream_res = res.GetResponseStream();
            int len = 1024 * 1024;
            byte[] tmpBuffer = new byte[len];// 1 mb once
            int readlen = 0;
            System.IO.MemoryStream ms = new System.IO.MemoryStream();
            do
            {
                readlen = stream_res.Read(tmpBuffer, 0, len);
                ms.Write(tmpBuffer, 0, readlen);
            }
            while (readlen > 0);
            retBuffer = ms.ToArray();

            // copy header to response
            for (int i = 0; i < res.Headers.Count; i++)
            {
                string[] s = res.Headers.GetValues(i);
                string k = res.Headers.Keys[i];
                string v = "";
                for (int j = 0; j < s.Length; j++)
                {
                    if (j > 0) v += ";";
                    v += s[j];
                }
                if (k == "Content-Type")
                {
                    Response.ContentType = v;
                }
                else if (k == "Set-Cookie")
                {
                    Response.SetCookie(new HttpCookie(v));
                }
                else if (k == "Last-Modified")
                {
                    Response.Headers.Set(k, v);
                }
                else if (k == "Content-Encoding")
                {
                    Response.Headers.Set(k, v);
                }
                //else
                //{
                //    Response.Headers.Set(k, v);
                //}
            }
            // write content of response
            Response.BinaryWrite(retBuffer);
        }
        catch (System.Net.WebException ex)
        {
            if (ex.Response != null)
            {
                Response.StatusCode = (int)(((System.Net.HttpWebResponse)ex.Response).StatusCode);
                Response.StatusDescription = ((System.Net.HttpWebResponse)ex.Response).StatusDescription;
            }
            else
            {
                // Server maybe crashed...
                Response.StatusCode = 500;
                Response.StatusDescription = "Internal Server error:" + ex.Message;
            }
        }
        catch (Exception ex)
        {
            Response.StatusCode = 404;
            Response.StatusDescription = "File not found:" + ex.Message;
        }
    }

    private bool ValidateWhiteList(string url)
    {
        bool ret = false;
        List<string> whiteList = new List<string>();
        //whiteList.Add("http://127.0.0.1");
        if (whiteList.Count == 0)
        {
            // no white list == all pass.
            ret = true;
        }
        else
        {
            // must validate white list
            foreach (string s in whiteList)
            {
                //if (url.StartsWith(s))
                if (url.ToLower().StartsWith(s.ToLower()))// CompareNoCase
                {
                    ret = true;
                    break;
                }
            }
        }

        return ret;
    }
</script>
