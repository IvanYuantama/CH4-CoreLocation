const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
require("dotenv").config();

const pickpointRoutes = require("./controllers/pickpoint.js");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => res.json({ status: "ok" }));
app.use("/api", pickpointRoutes);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
