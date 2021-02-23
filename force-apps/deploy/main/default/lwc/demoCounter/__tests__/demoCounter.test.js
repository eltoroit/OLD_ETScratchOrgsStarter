import { createElement } from "lwc";
import DemoCounter from "c/demoCounter";

describe("c-demo-counter", () => {
	afterEach(() => {
		// The jsdom instance is shared across test cases in a single file so reset the DOM
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	it("Counter initialized", () => {
		const element = createElement("c-demo-counter", {
			is: DemoCounter
		});
		document.body.appendChild(element);
		const input = element.shadowRoot.querySelector("lightning-input");
		expect(input.value).toBe(0);
	});

	it("Counter increases", async () => {
		const element = createElement("c-demo-counter", {
			is: DemoCounter
		});
		document.body.appendChild(element);
		const lwcInput = element.shadowRoot.querySelector("lightning-input");
		const lwcButton = element.shadowRoot.querySelector("lightning-button");
		await lwcButton.dispatchEvent(new CustomEvent("click"));
		expect(lwcInput.value).toBe(1);
	});

	it("Counter increases 5 times", async () => {
		const element = createElement("c-demo-counter", {
			is: DemoCounter
		});
		document.body.appendChild(element);
		const lwcInput = element.shadowRoot.querySelector("lightning-input");
		const lwcButton = element.shadowRoot.querySelector("lightning-button");
		await lwcButton.dispatchEvent(new CustomEvent("click"));
		await lwcButton.dispatchEvent(new CustomEvent("click"));
		await lwcButton.dispatchEvent(new CustomEvent("click"));
		await lwcButton.dispatchEvent(new CustomEvent("click"));
		await lwcButton.dispatchEvent(new CustomEvent("click"));
		expect(lwcInput.value).toBe(5);
	});

	it("Counter is a number", async () => {
		const element = createElement("c-demo-counter", {
			is: DemoCounter
		});
		document.body.appendChild(element);
		const lwcInput = element.shadowRoot.querySelector("lightning-input");
		lwcInput.value = "3";
		await lwcInput.dispatchEvent(new CustomEvent("change"));
		expect(Number(lwcInput.value)).toBe(3);
	});

	it("Counter must be a number", async () => {
		const element = createElement("c-demo-counter", {
			is: DemoCounter
		});
		document.body.appendChild(element);
		const lwcInput = element.shadowRoot.querySelector("lightning-input");
		const errorMsg = element.shadowRoot.querySelector('[data-id="errorMsg"]');
		expect(errorMsg.children.length).toBe(0);
		// Set invalid value
		lwcInput.value = "Hello";
		await lwcInput.dispatchEvent(new CustomEvent("change"));
		const errorCounter = element.shadowRoot.querySelector('[data-id="errorCount"]');
		// Error message should not be visible
		expect(lwcInput.value).toBe(0);
		expect(lwcInput.value).not.toBe("Hello");
		expect(errorMsg.children.length).toBe(1);
		expect(Number(errorCounter.textContent)).toBe(1);
	});

	// eslint-disable-next-line jest/no-commented-out-tests
	// it("fails", () => {
	// 	expect(1).toBe(2);
	// });
});
