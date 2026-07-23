import { useEffect } from "react";
import "@/App.css";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Landing from "@/pages/Landing";

function App() {
  useEffect(() => {
    document.title = "ProfilePilot — Native macOS workspace + browser-profile launcher";
  }, []);
  return (
    <div className="App">
      <div className="grain-overlay" aria-hidden="true" />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="*" element={<Landing />} />
        </Routes>
      </BrowserRouter>
    </div>
  );
}

export default App;
