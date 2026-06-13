import axios from "axios";

const api = axios.create({
  baseURL: "https://ridercraft-api.onrender.com"
});

export default api;
