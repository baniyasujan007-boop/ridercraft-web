import test from "node:test";
import assert from "node:assert/strict";
import http from "node:http";
import {
  fetchProductFromUrl,
  resolveProductImage,
} from "../controllers/productController.js";

// ------------------------------------------------------- unit: decision logic

test("existing HTTPS image URL is preserved unchanged", async () => {
  let probeCalls = 0;
  const original = "https://cdn.example.com/products/helmet.jpg";
  const result = await resolveProductImage(original, async () => {
    probeCalls += 1;
    return true;
  });
  assert.equal(result.url, original);
  assert.equal(result.note, "");
  assert.equal(probeCalls, 0, "https URLs must not be probed");
});

test("HTTP image with a reachable HTTPS version is upgraded", async () => {
  const result = await resolveProductImage(
    "http://cdn.example.com/products/helmet.jpg",
    async (httpsUrl) => {
      assert.equal(httpsUrl, "https://cdn.example.com/products/helmet.jpg");
      return true;
    }
  );
  assert.equal(result.url, "https://cdn.example.com/products/helmet.jpg");
  assert.match(result.note, /HTTPS/i);
});

test("protocol-relative image with a reachable HTTPS version is upgraded", async () => {
  const result = await resolveProductImage(
    "//cdn.example.com/products/gloves.jpg",
    async (httpsUrl) => {
      assert.equal(httpsUrl, "https://cdn.example.com/products/gloves.jpg");
      return true;
    }
  );
  assert.equal(result.url, "https://cdn.example.com/products/gloves.jpg");
});

test("HTTP image with an unreachable HTTPS version keeps the original", async () => {
  const original = "http://cdn.example.com/products/gloves.jpg";
  const result = await resolveProductImage(original, async () => false);
  assert.equal(result.url, original);
  assert.match(result.note, /retained/i);
});

test("HTTP image with a failing HTTPS probe keeps the original", async () => {
  const original = "http://cdn.example.com/products/jacket.jpg";
  const result = await resolveProductImage(original, async () => {
    throw new Error("probe down");
  });
  assert.equal(result.url, original);
  assert.match(result.note, /retained/i);
});

test("missing image URL resolves to an empty string gracefully", async () => {
  const result = await resolveProductImage("", async () => true);
  assert.deepEqual(result, { url: "", note: "" });
});

test("malformed/non-remote image URL is retained gracefully", async () => {
  const result = await resolveProductImage("images/local-pic.jpg", async () => true);
  assert.equal(result.url, "images/local-pic.jpg");
  assert.match(result.note, /retained|not a remote/i);
});

test("uppercase http:// scheme is still upgraded", async () => {
  const result = await resolveProductImage("HTTP://cdn.example.com/x.jpg", async () => true);
  assert.equal(result.url, "https://cdn.example.com/x.jpg");
});

// --------------------------------------------- integration: scraper + report

function startServer(routes) {
  return new Promise((resolve) => {
    const s = http.createServer((req, res) => {
      const handler = routes[req.url];
      if (!handler) {
        res.writeHead(404).end("not found");
        return;
      }
      res.writeHead(200, { "content-type": "text/html" });
      res.end(handler());
    });
    s.listen(0, "127.0.0.1", () =>
      resolve({ s, port: s.address().port })
    );
  });
}

const shut = (s) =>
  new Promise((resolve) => {
    s.closeAllConnections?.();
    s.close(resolve);
  });

function page(ogImage) {
  const meta = ogImage
    ? `<meta property="og:image" content="${ogImage}" />`
    : "";
  return `<html><head><title>Sample Product</title>${meta}</head><body></body></html>`;
}

async function scrape(url) {
  const res = {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
    },
  };
  await fetchProductFromUrl({ body: { url } }, res);
  return res;
}

test("scraped HTTPS image is returned unchanged", async () => {
  const { s, port } = await startServer({
    "/page": () => page("https://cdn.example.com/helm.jpg"),
  });
  try {
    const res = await scrape(`http://127.0.0.1:${port}/page`);
    assert.equal(res.statusCode, 200);
    assert.equal(res.body.image, "https://cdn.example.com/helm.jpg");
    assert.ok(!String(res.body.image).startsWith("http://"));
  } finally {
    await shut(s);
  }
});

test("scraped HTTP image that cannot be verified over HTTPS keeps the original and reports", async () => {
  const { s, port } = await startServer({
    "/page": () => page(`http://127.0.0.1:${port}/retained.jpg`),
  });
  try {
    const res = await scrape(`http://127.0.0.1:${port}/page`);
    assert.equal(res.statusCode, 200);
    assert.equal(res.body.image, `http://127.0.0.1:${port}/retained.jpg`);
    assert.equal(typeof res.body.imageNote, "string");
    assert.match(res.body.imageNote, /retained/i);
  } finally {
    await shut(s);
  }
});

test("page without an og:image fails gracefully with an empty image", async () => {
  const { s, port } = await startServer({ "/page": () => page(null) });
  try {
    const res = await scrape(`http://127.0.0.1:${port}/page`);
    assert.equal(res.statusCode, 200);
    assert.equal(res.body.image, "");
  } finally {
    await shut(s);
  }
});

test("malformed og:image is handled gracefully without crashing", async () => {
  const { s, port } = await startServer({
    "/page": () => page("bogus-local-path.jpg"),
  });
  try {
    const res = await scrape(`http://127.0.0.1:${port}/page`);
    assert.equal(res.statusCode, 200);
    assert.equal(res.body.image, "bogus-local-path.jpg");
    assert.equal(typeof res.body.imageNote, "string");
  } finally {
    await shut(s);
  }
});