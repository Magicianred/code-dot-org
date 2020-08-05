import {launchAsync} from '@microsoft/immersive-reader-sdk';

function getTokenAndSubdomainAsync() {
  return new Promise(function(resolve, reject) {
    $.ajax({
      url: '/api/immersion_reader_token',
      type: 'GET',
      success: function(data) {
        if (data.error) {
          reject(data.error);
        } else {
          resolve(data);
        }
      }
    });
  });
}

export default function handleLaunchImmersiveReader(title, text) {
  getTokenAndSubdomainAsync()
    .then(function(response) {
      const token = response.token;
      const subdomain = response.subdomain;
      const data = {
        title: title,
        chunks: [
          {
            content: text,
            lang: 'en'
          }
        ]
      };
      launchAsync(token, subdomain, data, {});
    })
    .catch(function(error) {
      console.log(error);
    });
}
