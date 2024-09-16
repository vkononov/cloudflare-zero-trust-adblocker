# Cloudflare Zero Trust Ad Blocker

Block ads across all devices without needing Pi-hole. Enjoy faster, ad-free browsing! 🎉

### Description
Tired of annoying ads slowing down your browsing? This script uses Cloudflare Zero Trust to block thousands of ads at the DNS level, improving speed, privacy, and overall browsing experience without the need for Pi-hole or additional hardware. It works across all your devices connected to Cloudflare's network, and is both simple to set up and highly customizable for advanced users.

## Table of Contents
1. [Overview](#overview)
2. [Why Use This?](#why-use-this)
3. [How Does It Work?](#how-does-it-work)
4. [Disclaimer](#disclaimer)
5. [Getting Started](#getting-started)
6. [Using the Script](#using-the-script)
7. [Troubleshooting](#troubleshooting)

## Overview
This project helps you block ads at the DNS level using Cloudflare’s Zero Trust platform. Ads can slow down websites, waste bandwidth, and compromise your privacy. By blocking them at the DNS level, you speed up browsing and maintain privacy across all devices, without needing to install Pi-hole or other software.

## Why Use This?

Ads don’t just annoy you — they make websites slower and can compromise your privacy. Blocking ads at the DNS level offers advantages over browser-based ad blockers:
- **Faster browsing**: Ads are blocked before they load.
- **No extra hardware**: Works across devices without needing Raspberry Pi or Pi-hole.
- **Cloudflare's global network**: Blocks ads regardless of where your device is connected.
- **Highly customizable**: You can fine-tune the ad list and manage exclusions.

### Pi-hole vs Cloudflare

1. **Global Ad-Blocking Coverage**: Pi-hole works locally, but Cloudflare Zero Trust applies globally.
2. **Scalability**: Cloudflare scales better with a large number of DNS queries.
3. **Maintenance**: No need for hardware maintenance or software updates like Pi-hole.
4. **Cross-network Support**: Works across all networks — home, office, or mobile.
5. **Superior Performance**: Cloudflare's global infrastructure ensures low-latency DNS lookups.

## How Does It Work?

This script helps block ads by using Cloudflare's powerful Zero Trust DNS filtering. Instead of relying on traditional ad blockers that work within your browser, this method stops ads from even reaching your devices by blocking them at the DNS level, which can speed up your browsing experience and make websites load faster.

Here’s the basic flow:

1. The script downloads a massive list of known ad-serving domains from a trusted source.
2. It then processes this list to remove any domains you’ve marked as exceptions (the exclusions file) so that important sites aren't accidentally blocked.
3. The domains are split into manageable chunks, because Cloudflare has limits on how many entries a single list can hold.
4. Each chunk is uploaded as a separate list to Cloudflare, and the old lists are deleted to keep things up to date.
5. Once the lists are created, a new DNS policy is made in Cloudflare, which tells their servers to block any domain in those lists.
6. From now on, any device connected to Cloudflare’s Zero Trust DNS will automatically block the ads before they even have a chance to load.

This approach provides a robust and network-wide solution for blocking ads, making it a great alternative to something like Pi-hole, especially for people who want an easy-to-manage, cloud-based solution that doesn’t require setting up dedicated hardware.

## Disclaimer
This script uses a large ad-blocking list, which may block more domains than expected, potentially breaking some sites. Use the exclusions list to whitelist necessary domains.

## Getting Started

1. **Create a FREE Cloudflare Account**
   - Sign up for a [Cloudflare account ↗](https://dash.cloudflare.com/sign-up).

2. **Create a Zero Trust organization**
   - On your Account Home in the [Cloudflare dashboard ↗](https://dash.cloudflare.com/), select the Zero Trust icon.
   - On the onboarding screen, choose a team name. The team name is a unique, internal identifier for your Zero Trust organization.
   - Complete your onboarding by selecting a FREE subscription.

3. **Configure Zero Trust Authentication**
   - Configure [One-time PIN](https://developers.cloudflare.com/cloudflare-one/identity/one-time-pin/) (easy) or connect a [third-party identity provider](https://developers.cloudflare.com/cloudflare-one/identity/idp-integration/) (advanced) in Zero Trust. This is the login method you will use when authenticating to add a new device to your Zero Trust setup.

4. **Install the WARP client on your devices**
   - Install a free [Cloudflare WARP ↗](https://1.1.1.1) client on your devices to connect to Cloudflare's network.

5. **Login to Zero Trust on Your Device**
   - On your device, go to the Settings section in the WARP client and insert your organization’s team name from step 2.

6. **Cloudflare API Token**
   - Generate your API key from the Cloudflare dashboard (**Account > API Tokens**).

7. **Ruby and Bundler**
   - Ensure you have Ruby and Bundler installed on your machine:
     ```bash
     gem install bundler
     ```

## Using the Script

### Running the Script

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/yourusername/cloudflare-zero-trust-adblocker.git
   cd cloudflare-zero-trust-adblocker
   ```

2. **Install Dependencies**:

   Install the required Ruby gems by running:

   ```bash
   bundle install
   ```

3. **Configure Environment Variables**:

   The script relies on certain sensitive variables like API keys, account IDs, and URLs. Set these environment variables in your terminal or add them to an `.env` file.

   ```bash
   CLOUDFLARE_API_KEY=your_cloudflare_api_key
   CLOUDFLARE_EMAIL=your_email@example.com
   CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id
   ```

   > See `config/application.rb` for additional environment variables that can be set.

4. **Run the Script**:

   ```bash
   ruby lib/main.rb
   ```

   This will automatically download the latest ad list, apply any exclusions, and update your Cloudflare Gateway DNS policies to block unwanted hostnames.

### Setting Up Exclusions (Optional)
To prevent blocking certain domains, create an `exclusions.txt` file in the root of the project. Add the domains you want to exclude, one per line.

   ```plaintext
   example.com
   ads.google.com
   ```

### Automating with Cron

> This step is only necessary if you want to benefit from automatic ad list updates.

Install Ruby gems in non-development mode:

```bash
gem install bundler --conservative
bundle config --local path 'vendor/bundle'
bundle config --local without 'development:test'
bundle check || bundle install -j4
```

For convenience, you can automate this script using a cron job. Example for running it weekly:

```bash
0 0 * * 0 cd /path/to/your/project && $HOME/.rbenv/shims/bundle exec ruby lib/main.rb
```

## Debugging

To increase verbosity and see detailed logs, set the `LOG_LEVEL` environment variable to `debug`:

```bash
LOG_LEVEL=debug ruby lib/main.rb
```

## Troubleshooting

### Script Fails to Create a Policy

- Ensure that your Cloudflare account has the appropriate API permissions to manage Gateway lists and policies.
- Verify that your environment variables are set up correctly and that they contain the correct API token and account details.

### DNS Queries Not Being Blocked

- Make sure your devices are connected to Cloudflare Zero Trust. You can verify by visiting [1.1.1.1/help](https://1.1.1.1/help).
- Check the logs for any errors or issues with the API requests.

## Contributing

Feel free to fork this repository and submit pull requests to improve the functionality or fix bugs. Contributions are always welcome.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

