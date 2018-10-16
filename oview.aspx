<%@ Page Language="C#" %>
<script runat="server">
    private void Page_Load(object sender, EventArgs e)
    {
        //把aspx串的參數接到新url上
        //string ClientQueryString = HttpUtility.UrlDecode(Page.ClientQueryString);
        //string url = "http://127.0.0.1:8080/oview?" + ClientQueryString;
        string url;
        //if (Page.ClientQueryString.IndexOf("resource=") == 0)
        //{
        //    url= "http://127.0.0.1:8080/resource?" + Page.ClientQueryString;
        //}
        //else if (Page.ClientQueryString.IndexOf("type=") == 0)
        //{
        //    url= "http://127.0.0.1:8080/oview?" + Page.ClientQueryString;
        //}
        //else
        {
            url=HttpUtility.UrlDecode(Page.ClientQueryString);
        }
        //判斷是GET還是POST
        bool bPOST = Request.InputStream.Length > 0;
        byte[] postBuffer = null;
        if (bPOST)//取得POST資料
        {
            postBuffer = new byte[Request.InputStream.Length];
            Request.InputStream.Read(postBuffer, 0, postBuffer.Length);
        }
        System.Net.HttpWebRequest req = System.Net.WebRequest.Create(url) as System.Net.HttpWebRequest;
        req.Method = bPOST ? "POST" : "GET";
		if (bPOST)
		{
			req.ContentLength = postBuffer.Length;
			req.ContentType = "application/json";
		}		
        req.UserAgent = "PilotGaea Proxy Server";

        //複製檔頭的cookie
        NameValueCollection headers = Request.Headers;
        for (int i = 0; i < headers.Count; i++)
        {
            //Response.Write(headers.GetKey(i) + ":" + headers.Get(i) + "<BR>");
            if (headers.GetKey(i) == "Cookie")
            {
                req.Headers.Set("Cookie", headers.Get(i));
                break;
            }
        }

        byte[] retBuffer = null;
        try
        {
            if (bPOST)
            {
                //上傳
                System.IO.Stream stream_req = req.GetRequestStream();
                stream_req.Write(postBuffer, 0, postBuffer.Length);
				stream_req.Flush();
				stream_req.Close();				
            }

            System.Net.HttpWebResponse res = req.GetResponse() as System.Net.HttpWebResponse;
            System.IO.Stream stream_res = res.GetResponseStream();
            //retBuffer = new byte[stream_res.Length];
            //stream_res.Read(retBuffer, 0, (int)stream_res.Length);
            int len = 1024 * 1024;
            byte[] tmpBuffer = new byte[len];//一次1MB
            int readlen = 0;
            System.IO.MemoryStream ms = new System.IO.MemoryStream();
            do {
                readlen = stream_res.Read(tmpBuffer, 0, len);
                ms.Write(tmpBuffer, 0, readlen);
            }
            while (readlen>0);
            retBuffer = ms.ToArray();

            //複製回應的檔頭
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
            //寫入回應的本文
            Response.BinaryWrite(retBuffer);
        }
        catch(System.Net.WebException ex) {
            if (ex.Response != null)
            {
                Response.StatusCode = (int)(((System.Net.HttpWebResponse)ex.Response).StatusCode);
                Response.StatusDescription = ((System.Net.HttpWebResponse)ex.Response).StatusDescription;
            }
            else
            {
                //通常是伺服器沒開
                Response.StatusCode = 500;
                Response.StatusDescription = "Internal Server error:" + ex.Message;
            }
        }
        catch(Exception ex) {
            Response.StatusCode = 404;
            Response.StatusDescription = "File not found:" + ex.Message;
        }
    }

</script>